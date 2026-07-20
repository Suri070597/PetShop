import 'dart:io';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../app/constants/app_constants.dart';
import '../../app/constants/cloudinary_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/password_hasher.dart';
import '../datasources/cloudinary/cloudinary_service.dart';
import '../datasources/drift/app_database.dart';
import '../datasources/firebase/auth_service.dart';
import '../datasources/local/preferences_service.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuthService authService,
    required AppDatabase database,
    required PreferencesService preferences,
    required CloudinaryService cloudinaryService,
  }) : _authService = authService,
       _database = database,
       _preferences = preferences,
       _cloudinaryService = cloudinaryService;

  final FirebaseAuthService _authService;
  final AppDatabase _database;
  final PreferencesService _preferences;
  final CloudinaryService _cloudinaryService;

  fb.User? get firebaseUser => _authService.currentUser;

  Future<LocalUser?> restoreSession() async {
    await _database.seedCatalog();
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      await _preferences.clearSession();
      return null;
    }
    final refreshed = await _authService.reloadCurrentUser() ?? firebaseUser;
    final localUser = await _upsertFromFirebase(
      refreshed,
      emailVerified: refreshed.emailVerified,
    );
    await _preferences.saveCurrentUserId(localUser.id);
    return localUser;
  }

  Future<LocalUser> registerWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _authService.createWithEmail(
      email: email.trim(),
      password: password,
      displayName: fullName.trim(),
    );
    final user = credential.user;
    if (user == null) {
      throw const AppException('Không thể tạo tài khoản Firebase.');
    }

    final localUser = await _upsertFromFirebase(
      user,
      fullName: fullName.trim(),
      phone: phone.trim().isEmpty ? null : phone.trim(),
      passwordHash: PasswordHasher.hashPassword(password),
      authProvider: 'email',
      emailVerified: false,
    );
    await _preferences.saveCurrentUserId(localUser.id);
    await sendVerificationEmail();
    return localUser;
  }

  Future<LocalUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AppException('Đăng nhập không thành công.');
    }

    final passwordHash = PasswordHasher.hashPassword(password);
    final localUser = await _upsertFromFirebase(
      user,
      passwordHash: passwordHash,
      authProvider: 'email',
      emailVerified: user.emailVerified,
    );
    await _preferences.saveCurrentUserId(localUser.id);
    return localUser;
  }

  Future<LocalUser> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    final user = credential.user;
    if (user == null) {
      throw const AppException('Đăng nhập Google không thành công.');
    }

    final localUser = await _upsertFromFirebase(
      user,
      authProvider: 'google',
      emailVerified: user.emailVerified,
    );
    await _preferences.saveCurrentUserId(localUser.id);
    return localUser;
  }

  Future<void> sendVerificationEmail() {
    return _authService.sendEmailVerification(
      actionCodeSettings: fb.ActionCodeSettings(
        url: AppConstants.emailVerificationContinueUrl,
        handleCodeInApp: true,
        androidPackageName: AppConstants.androidPackageName,
        androidInstallApp: true,
      ),
    );
  }

  Future<LocalUser> checkEmailVerificationStatus() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('Phiên đăng nhập đã hết hạn.');
    }

    final refreshed = await _authService.reloadCurrentUser() ?? user;
    if (!refreshed.emailVerified) {
      throw const AppException(
        'Email chưa được xác minh. Vui lòng mở link trong hộp thư rồi thử lại.',
      );
    }

    final localUser = await _upsertFromFirebase(refreshed, emailVerified: true);
    await _preferences.saveCurrentUserId(localUser.id);
    return localUser;
  }

  Future<LocalUser> applyEmailVerificationLink(Uri uri) async {
    final code = _extractActionCode(uri);
    if (code == null || code.isEmpty) {
      throw const AppException('Liên kết xác minh không hợp lệ.');
    }

    await _authService.checkActionCode(code);
    await _authService.applyActionCode(code);
    return checkEmailVerificationStatus();
  }

  Future<void> resendVerificationEmail() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('Chưa có tài khoản để gửi lại email xác minh.');
    }
    if (user.emailVerified) {
      return;
    }
    await sendVerificationEmail();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email.trim());
    } on fb.FirebaseAuthException catch (error) {
      throw AppException(_firebaseMessage(error));
    }
  }

  Future<LocalUser?> currentLocalUser() async {
    final userId = _authService.currentUser?.uid ?? _preferences.currentUserId;
    if (userId == null) {
      return null;
    }
    final user = await _database.findUserById(userId);
    if (user == null || !user.emailVerified) {
      return null;
    }
    return user;
  }

  Future<LocalUser> updateProfile({
    required String fullName,
    required String phone,
    File? avatarFile,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw const AppException('Phiên đăng nhập đã hết hạn.');
    }

    final existing = await _database.findUserById(user.uid);
    if (existing == null) {
      throw const AppException('Không tìm thấy hồ sơ người dùng.');
    }

    String? avatarUrl;
    if (avatarFile != null) {
      avatarUrl = await _cloudinaryService.uploadImage(
        file: avatarFile,
        folder: CloudinaryConstants.usersAvatarFolder,
        publicId: user.uid,
      );
    }

    await _database.updateUserProfile(
      userId: user.uid,
      fullName: fullName.trim(),
      phone: phone.trim(),
      avatar: avatarUrl,
    );

    final updated = await _database.findUserById(user.uid);
    if (updated == null) {
      throw const AppException('Không thể cập nhật hồ sơ.');
    }
    return updated;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    developer.log(
      'Bước 1: Repository kiểm tra local user',
      name: 'ChangePassword',
    );
    final localUser = await currentLocalUser();
    if (localUser == null) {
      throw const AppException('Phiên đăng nhập đã hết hạn.');
    }
    if (localUser.authProvider != 'email') {
      throw const AppException(
        'Tài khoản Google không thể đổi mật khẩu trong ứng dụng.',
      );
    }
    try {
      developer.log(
        'Bước 3-4: Gọi Firebase reauthenticate/updatePassword',
        name: 'ChangePassword',
      );
      await _authService
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw const AppException(
              'Đổi mật khẩu quá thời gian chờ. Vui lòng kiểm tra kết nối mạng và thử lại.',
            ),
          );

      developer.log('Bước 5: Update Drift Password', name: 'ChangePassword');
      final updatedRows = await _database.updateUserPasswordHash(
        userId: localUser.id,
        passwordHash: PasswordHasher.hashPassword(newPassword),
      );
      if (updatedRows == 0) {
        throw const AppException(
          'Firebase đã đổi mật khẩu nhưng không tìm thấy tài khoản trong Drift để cập nhật.',
        );
      }
      developer.log('Bước 6: Hoàn thành', name: 'ChangePassword');
    } on fb.FirebaseAuthException catch (error) {
      developer.log(
        'Lỗi Firebase ở bước đổi mật khẩu: ${error.code} - ${error.message}',
        name: 'ChangePassword',
        error: error,
      );
      throw AppException(_firebaseMessage(error));
    } on AppException catch (error) {
      developer.log(
        'Lỗi ứng dụng ở bước đổi mật khẩu: ${error.message}',
        name: 'ChangePassword',
        error: error,
      );
      rethrow;
    } on Object catch (error) {
      developer.log(
        'Lỗi không xác định ở bước đổi mật khẩu',
        name: 'ChangePassword',
        error: error,
      );
      throw const AppException('Không thể đổi mật khẩu. Vui lòng thử lại sau.');
    }
  }

  bool shouldShowWelcome(LocalUser user) =>
      !_preferences.hasShownWelcome(user.id);

  Future<void> markWelcomeShown(LocalUser user) {
    return _preferences.markWelcomeShown(user.id);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _preferences.clearSession();
  }

  Future<LocalUser> _upsertFromFirebase(
    fb.User user, {
    String? fullName,
    String? phone,
    String? passwordHash,
    String? authProvider,
    bool? emailVerified,
  }) async {
    final existing = await _database.findUserById(user.uid);
    final resolvedEmail = user.email ?? existing?.email ?? '';
    final resolvedName =
        fullName ??
        user.displayName ??
        existing?.fullName ??
        'Khách hàng PetJoy';

    await _database.upsertUser(
      LocalUsersCompanion(
        id: Value(user.uid),
        fullName: Value(resolvedName),
        email: Value(resolvedEmail),
        phone: Value(phone ?? existing?.phone),
        avatar: Value(existing?.avatar ?? user.photoURL),
        passwordHash: Value(passwordHash ?? existing?.passwordHash),
        authProvider: Value(authProvider ?? existing?.authProvider ?? 'email'),
        role: Value(existing?.role ?? 'customer'),
        createdAt: Value(existing?.createdAt ?? DateTime.now()),
        emailVerified: Value(
          emailVerified ??
              user.emailVerified || existing?.emailVerified == true,
        ),
        status: Value(existing?.status ?? true),
      ),
    );

    final saved = await _database.findUserById(user.uid);
    if (saved == null) {
      throw const AppException('Không thể lưu tài khoản vào cơ sở dữ liệu.');
    }
    return saved;
  }

  String? _extractActionCode(Uri uri) {
    final directCode = uri.queryParameters['oobCode'];
    if (directCode != null) {
      return directCode;
    }

    final nestedLink =
        uri.queryParameters['link'] ?? uri.queryParameters['continueUrl'];
    if (nestedLink == null) {
      return null;
    }
    final decoded = Uri.tryParse(Uri.decodeComponent(nestedLink));
    return decoded?.queryParameters['oobCode'];
  }

  String _firebaseMessage(fb.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Email không hợp lệ.',
      'user-not-found' => 'Không tìm thấy tài khoản với email này.',
      'wrong-password' ||
      'invalid-credential' => 'Mật khẩu hiện tại không đúng.',
      'weak-password' => 'Mật khẩu mới quá yếu.',
      'too-many-requests' =>
        'Bạn đã thử quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.',
      'requires-recent-login' =>
        'Phiên đăng nhập cần được xác thực lại trước khi đổi mật khẩu.',
      'user-disabled' => 'Tài khoản này đã bị vô hiệu hóa.',
      'user-mismatch' =>
        'Thông tin xác thực không khớp với tài khoản hiện tại.',
      'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
      _ => error.message ?? 'Thao tác Firebase không thành công.',
    };
  }
}

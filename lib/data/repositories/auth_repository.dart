import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../app/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/password_hasher.dart';
import '../datasources/drift/app_database.dart';
import '../datasources/firebase/auth_service.dart';
import '../datasources/local/preferences_service.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuthService authService,
    required AppDatabase database,
    required PreferencesService preferences,
  }) : _authService = authService,
       _database = database,
       _preferences = preferences;

  final FirebaseAuthService _authService;
  final AppDatabase _database;
  final PreferencesService _preferences;

  fb.User? get firebaseUser => _authService.currentUser;

  Future<LocalUser?> restoreSession() async {
    await _database.seedCatalog();
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      await _preferences.clearSession();
      return null;
    }
    final localUser = await _upsertFromFirebase(firebaseUser);
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
      throw const AppException('Khong the tao tai khoan Firebase.');
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
      throw const AppException('Dang nhap khong thanh cong.');
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
      throw const AppException('Dang nhap Google khong thanh cong.');
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
      throw const AppException('Phien dang nhap da het han.');
    }

    final refreshed = await _authService.reloadCurrentUser() ?? user;
    if (!refreshed.emailVerified) {
      throw const AppException(
        'Email chua duoc xac minh. Vui long mo link trong hop thu roi thu lai.',
      );
    }

    final localUser = await _upsertFromFirebase(refreshed, emailVerified: true);
    await _preferences.saveCurrentUserId(localUser.id);
    return localUser;
  }

  Future<LocalUser> applyEmailVerificationLink(Uri uri) async {
    final code = _extractActionCode(uri);
    if (code == null || code.isEmpty) {
      throw const AppException('Lien ket xac minh khong hop le.');
    }

    await _authService.checkActionCode(code);
    await _authService.applyActionCode(code);
    return checkEmailVerificationStatus();
  }

  Future<void> resendVerificationEmail() async {
    final localUser = await currentLocalUser();
    if (localUser == null) {
      throw const AppException('Chua co tai khoan de gui lai email xac minh.');
    }
    if (localUser.emailVerified) {
      return;
    }
    await sendVerificationEmail();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email.trim());
  }

  Future<LocalUser?> currentLocalUser() async {
    final userId = _authService.currentUser?.uid ?? _preferences.currentUserId;
    if (userId == null) {
      return null;
    }
    return _database.findUserById(userId);
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
        'Khach hang PetJoy';

    await _database.upsertUser(
      LocalUsersCompanion(
        id: Value(user.uid),
        fullName: Value(resolvedName),
        email: Value(resolvedEmail),
        phone: Value(phone ?? existing?.phone),
        avatar: Value(user.photoURL ?? existing?.avatar),
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
      throw const AppException('Khong the luu tai khoan vao DB local.');
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
}

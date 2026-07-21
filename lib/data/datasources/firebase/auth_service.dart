import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/platform_helper.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? _safeGetFirebaseAuth(),
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  static const _authTimeout = Duration(seconds: 30);

  static fb.FirebaseAuth? _safeGetFirebaseAuth() {
    try {
      return fb.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  fb.User? get currentUser {
    try {
      return _firebaseAuth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<fb.User?> authStateChanges() {
    try {
      return _firebaseAuth?.authStateChanges() ?? Stream.value(null);
    } catch (_) {
      return Stream.value(null);
    }
  }

  Future<fb.UserCredential> createWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    return credential;
  }

  Future<fb.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb.UserCredential> signInWithGoogle() async {
    if (PlatformHelper.isWindows) {
      throw fb.FirebaseAuthException(
        code: 'google-sign-in-not-supported',
        message: 'Đăng nhập Google không hỗ trợ trên Windows.',
      );
    }
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw fb.FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Người dùng đã hủy đăng nhập Google.',
      );
    }

    final googleAuth = await account.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> sendEmailVerification({
    required fb.ActionCodeSettings actionCodeSettings,
  }) async {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw fb.FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Chưa có phiên đăng nhập.',
      );
    }
    await user.sendEmailVerification(actionCodeSettings);
  }

  Future<fb.ActionCodeInfo> checkActionCode(String code) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.checkActionCode(code);
  }

  Future<void> applyActionCode(String code) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.applyActionCode(code);
  }

  Future<void> sendPasswordResetEmail(String email) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    debugPrint('[ChangePassword][Firebase] Bước 2: Lấy currentUser');
    final auth = _firebaseAuth;
    if (auth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message:
            'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }

    var user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw fb.FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Chưa có phiên đăng nhập hợp lệ.',
      );
    }
    debugPrint(
      '[ChangePassword][Firebase] CurrentUser uid=${user.uid}, email=$email',
    );

    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    user = await _reauthenticateEmailUser(
      auth: auth,
      user: user,
      email: email,
      currentPassword: currentPassword,
      credential: credential,
    );

    debugPrint('[ChangePassword][Firebase] Bước 4: Update Firebase Password');
    await user
        .updatePassword(newPassword)
        .timeout(
          _authTimeout,
          onTimeout: () => throw fb.FirebaseAuthException(
            code: 'update-password-timeout',
            message:
                'Firebase mất quá nhiều thời gian khi cập nhật mật khẩu mới.',
          ),
        );
    debugPrint('[ChangePassword][Firebase] Firebase đổi mật khẩu thành công');
  }

  Future<fb.User> _reauthenticateEmailUser({
    required fb.FirebaseAuth auth,
    required fb.User user,
    required String email,
    required String currentPassword,
    required fb.AuthCredential credential,
  }) async {
    if (PlatformHelper.isWindows) {
      debugPrint(
        '[ChangePassword][Firebase] Bước 3: Windows xác thực lại bằng signInWithEmailAndPassword',
      );
      final userCredential = await auth
          .signInWithEmailAndPassword(email: email, password: currentPassword)
          .timeout(
            _authTimeout,
            onTimeout: () => throw fb.FirebaseAuthException(
              code: 'reauthenticate-timeout',
              message:
                  'Firebase mất quá nhiều thời gian khi xác thực lại mật khẩu hiện tại.',
            ),
          );
      final signedInUser = userCredential.user ?? auth.currentUser;
      if (signedInUser == null) {
        throw fb.FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Không thể xác thực lại tài khoản.',
        );
      }
      if (signedInUser.uid != user.uid) {
        throw fb.FirebaseAuthException(
          code: 'user-mismatch',
          message: 'Thông tin xác thực không khớp với tài khoản hiện tại.',
        );
      }
      return signedInUser;
    }

    debugPrint('[ChangePassword][Firebase] Bước 3: Reauthenticate');
    final userCredential = await user
        .reauthenticateWithCredential(credential)
        .timeout(
          _authTimeout,
          onTimeout: () => throw fb.FirebaseAuthException(
            code: 'reauthenticate-timeout',
            message:
                'Firebase mất quá nhiều thời gian khi xác thực lại mật khẩu hiện tại.',
          ),
        );
    return userCredential.user ?? auth.currentUser ?? user;
  }

  Future<fb.User?> reloadCurrentUser() async {
    if (_firebaseAuth == null) {
      return null;
    }
    final user = _firebaseAuth.currentUser;
    await user?.reload();
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    if (!PlatformHelper.isWindows) {
      await _googleSignIn.signOut();
    }
    if (_firebaseAuth != null) {
      await _firebaseAuth.signOut();
    }
  }
}

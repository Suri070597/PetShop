import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
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
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
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
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
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
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
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
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
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
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.checkActionCode(code);
  }

  Future<void> applyActionCode(String code) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.applyActionCode(code);
  }

  Future<void> sendPasswordResetEmail(String email) {
    if (_firebaseAuth == null) {
      throw fb.FirebaseAuthException(
        code: 'no-firebase-app',
        message: 'Dịch vụ xác thực Firebase chưa được cấu hình trên thiết bị này.',
      );
    }
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    developer.log('Bước 2: Lấy Firebase currentUser', name: 'ChangePassword');
    final user = _firebaseAuth?.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw fb.FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Chưa có phiên đăng nhập hợp lệ.',
      );
    }

    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    developer.log('Bước 3: Reauthenticate', name: 'ChangePassword');
    await user.reauthenticateWithCredential(credential);

    developer.log('Bước 4: Update Firebase Password', name: 'ChangePassword');
    await user.updatePassword(newPassword);
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

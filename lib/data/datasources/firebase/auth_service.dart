import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/platform_helper.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  fb.User? get currentUser => _firebaseAuth.currentUser;

  Stream<fb.User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<fb.UserCredential> createWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
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
    return _firebaseAuth.checkActionCode(code);
  }

  Future<void> applyActionCode(String code) {
    return _firebaseAuth.applyActionCode(code);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    developer.log('Bước 2: Lấy Firebase currentUser', name: 'ChangePassword');
    final user = _firebaseAuth.currentUser;
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
    final user = _firebaseAuth.currentUser;
    await user?.reload();
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    if (!PlatformHelper.isWindows) {
      await _googleSignIn.signOut();
    }
    await _firebaseAuth.signOut();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../data/datasources/drift/app_database.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<LocalUser?>>((ref) {
      return AuthController(ref);
    });

class AuthController extends StateNotifier<AsyncValue<LocalUser?>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<LocalUser?> restoreSession() async {
    state = const AsyncLoading();
    return _guard(() => _ref.read(authRepositoryProvider).restoreSession());
  }

  Future<LocalUser> registerWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    state = const AsyncLoading();
    return _guard(
      () => _ref
          .read(authRepositoryProvider)
          .registerWithEmail(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password,
          ),
    );
  }

  Future<LocalUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    state = const AsyncLoading();
    return _guard(
      () => _ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<LocalUser> signInWithGoogle() {
    state = const AsyncLoading();
    return _guard(() => _ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<LocalUser> checkEmailVerificationStatus() {
    state = const AsyncLoading();
    return _guard(
      () => _ref.read(authRepositoryProvider).checkEmailVerificationStatus(),
    );
  }

  Future<LocalUser> applyEmailVerificationLink(Uri uri) {
    state = const AsyncLoading();
    return _guard(
      () => _ref.read(authRepositoryProvider).applyEmailVerificationLink(uri),
    );
  }

  Future<void> resendVerificationEmail() {
    return _ref.read(authRepositoryProvider).resendVerificationEmail();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      if (result is LocalUser?) {
        state = AsyncData(result);
      } else if (result is LocalUser) {
        state = AsyncData(result);
      }
      return result;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

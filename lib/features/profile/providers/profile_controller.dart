import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../data/datasources/drift/app_database.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<LocalUser?>>((ref) {
      return ProfileController(ref);
    });

class ProfileController extends StateNotifier<AsyncValue<LocalUser?>> {
  ProfileController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<File?> pickAvatar() {
    return _ref.read(imageServiceProvider).pickImage();
  }

  Future<LocalUser> updateProfile({
    required String fullName,
    required String phone,
    File? avatarFile,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .updateProfile(
            fullName: fullName,
            phone: phone,
            avatarFile: avatarFile,
          );
      state = AsyncData(user);
      return user;
    } on Object catch (error, stackTrace) {
      final user = await _ref.read(authRepositoryProvider).currentLocalUser();
      state = user == null
          ? AsyncError(error, stackTrace)
          : AsyncValue<LocalUser?>.data(user);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    try {
      debugPrint('[ChangePassword][Provider] Gọi Repository đổi mật khẩu');
      await _ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      final user = await _ref.read(authRepositoryProvider).currentLocalUser();
      debugPrint('[ChangePassword][Provider] Hoàn thành, user=${user?.email}');
      state = AsyncData(user);
    } on Object catch (error, stackTrace) {
      debugPrint('[ChangePassword][Provider] Lỗi đổi mật khẩu: $error');
      final user = await _ref.read(authRepositoryProvider).currentLocalUser();
      state = user == null
          ? AsyncError(error, stackTrace)
          : AsyncValue<LocalUser?>.data(user);
      rethrow;
    } finally {
      if (state.isLoading) {
        final user = await _ref.read(authRepositoryProvider).currentLocalUser();
        state = AsyncData(user);
      }
    }
  }
}

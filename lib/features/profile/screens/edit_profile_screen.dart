import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/cloudinary_constants.dart';
import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/drift/app_database.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/profile_controller.dart';
import 'profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  LocalUser? _initialUser;
  File? _avatarFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialUser != null) {
      return;
    }
    final user = ModalRoute.of(context)?.settings.arguments;
    if (user is LocalUser) {
      _initialUser = user;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ref
          .read(profileControllerProvider.notifier)
          .pickAvatar();
      if (file == null || !mounted) {
        return;
      }
      setState(() => _avatarFile = file);
    } on Object catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            fullName: _nameController.text,
            phone: _phoneController.text,
            avatarFile: _avatarFile,
          );
      ref.invalidate(profileSummaryProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hồ sơ đã được cập nhật.')));
      Navigator.pop(context);
    } on Object catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = _initialUser;
    final isLoading = ref.watch(profileControllerProvider).isLoading;
    final avatarUrl =
        user?.avatar ??
        ref.watch(authRepositoryProvider).firebaseUser?.photoURL ??
        CloudinaryConstants.profileFallbackAvatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Không tìm thấy hồ sơ.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _EditableAvatar(
                                  file: _avatarFile,
                                  imageUrl: avatarUrl,
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: 0,
                                  child: IconButton.filled(
                                    onPressed: isLoading ? null : _pickAvatar,
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    tooltip: 'Chọn ảnh đại diện',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          PetTextField(
                            controller: _nameController,
                            labelText: 'Họ và tên',
                            hintText: 'Nguyễn An',
                            validator: (value) =>
                                Validators.required(value, 'họ và tên'),
                          ),
                          const SizedBox(height: 16),
                          PetTextField(
                            controller: _phoneController,
                            labelText: 'Số điện thoại',
                            hintText: '0900000000',
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 16),
                          _ReadOnlyInfo(label: 'Email', value: user.email),
                          const SizedBox(height: 12),
                          _ReadOnlyInfo(label: 'Vai trò', value: user.role),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: 'Lưu thay đổi',
                            icon: Icons.save_outlined,
                            isLoading: isLoading,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.file, required this.imageUrl});

  final File? file;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.forest,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: file == null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.mist,
                  child: Icon(Icons.person, color: AppColors.muted),
                ),
              )
            : Image.file(file!, fit: BoxFit.cover),
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

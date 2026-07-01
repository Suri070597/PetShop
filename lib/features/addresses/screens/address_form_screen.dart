import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/validators.dart';
import '../../../data/datasources/drift/app_database.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({
    super.key,
    required this.userId,
    this.address,
  });

  final String userId;
  final AddressesData? address;

  bool get isEditing => address != null;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _receiverNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _provinceController;
  late final TextEditingController _districtController;
  late final TextEditingController _wardController;
  late final TextEditingController _streetController;

  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _receiverNameController = TextEditingController(
      text: address?.receiverName ?? '',
    );
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _provinceController = TextEditingController(text: address?.province ?? '');
    _districtController = TextEditingController(text: address?.district ?? '');
    _wardController = TextEditingController(text: address?.ward ?? '');
    _streetController = TextEditingController(text: address?.street ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(addressRepositoryProvider);

      if (widget.isEditing) {
        await repository.updateAddress(
          addressId: widget.address!.addressId,
          userId: widget.userId,
          receiverName: _receiverNameController.text,
          phone: _phoneController.text,
          province: _provinceController.text,
          district: _districtController.text,
          ward: _wardController.text,
          street: _streetController.text,
          isDefault: _isDefault,
        );
      } else {
        await repository.addAddress(
          userId: widget.userId,
          receiverName: _receiverNameController.text,
          phone: _phoneController.text,
          province: _provinceController.text,
          district: _districtController.text,
          ward: _wardController.text,
          street: _streetController.text,
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu địa chỉ: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
            children: [
              PetTextField(
                controller: _receiverNameController,
                labelText: 'Người nhận',
                hintText: 'Nhập họ tên người nhận',
                icon: Icons.person_outline,
                validator: (value) => Validators.required(value, 'người nhận'),
              ),
              const SizedBox(height: 16),
              PetTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                hintText: 'Nhập số điện thoại',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.required(value, 'số điện thoại'),
              ),
              const SizedBox(height: 16),
              PetTextField(
                controller: _provinceController,
                labelText: 'Tỉnh/Thành phố',
                hintText: 'Nhập tỉnh hoặc thành phố',
                icon: Icons.location_city_outlined,
                validator: (value) =>
                    Validators.required(value, 'tỉnh/thành phố'),
              ),
              const SizedBox(height: 16),
              PetTextField(
                controller: _districtController,
                labelText: 'Quận/Huyện',
                hintText: 'Nhập quận hoặc huyện',
                icon: Icons.map_outlined,
                validator: (value) => Validators.required(value, 'quận/huyện'),
              ),
              const SizedBox(height: 16),
              PetTextField(
                controller: _wardController,
                labelText: 'Phường/Xã',
                hintText: 'Nhập phường hoặc xã',
                icon: Icons.place_outlined,
                validator: (value) => Validators.required(value, 'phường/xã'),
              ),
              const SizedBox(height: 16),
              PetTextField(
                controller: _streetController,
                labelText: 'Địa chỉ cụ thể',
                hintText: 'Số nhà, tên đường',
                icon: Icons.home_outlined,
                validator: (value) =>
                    Validators.required(value, 'địa chỉ cụ thể'),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeColor: AppColors.forest,
                title: const Text(
                  'Đặt làm địa chỉ mặc định',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: widget.isEditing ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _saveAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/theme.dart';
import '../../data/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentPhotoUrl;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    this.currentPhotoUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = UserService();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _pickedFile;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.textPrimary),
              title: Text('Choose from gallery',
                  style: AppTypography.body2),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.textPrimary),
              title:
                  Text('Take a photo', style: AppTypography.body2),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (choice == null) return;
    final img = await picker.pickImage(
        source: choice, imageQuality: 80, maxWidth: 512);
    if (img == null) return;
    setState(() => _pickedFile = File(img.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_pickedFile != null) {
        setState(() => _uploading = true);
        await _service.uploadProfilePhoto(_pickedFile!);
        setState(() => _uploading = false);
      }
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty && name != widget.currentName) {
        await _service.updateDisplayName(name);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textPrimary)),
            backgroundColor: AppColors.surface,
          ),
        );
        context.pop(true); // pass true = profile changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textPrimary)),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Edit Profile', style: AppTypography.subtitle1),
        centerTitle: false,
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: (_saving || _uploading) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : Text('Save', style: AppTypography.link),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePad,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // ── Avatar picker ────────────────────────────────────
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: AppSpacing.avatarLg / 2,
                      backgroundColor: AppColors.primary,
                      backgroundImage: _pickedFile != null
                          ? FileImage(_pickedFile!) as ImageProvider
                          : (widget.currentPhotoUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.currentPhotoUrl!)
                              : null),
                      child: (_pickedFile == null &&
                              widget.currentPhotoUrl == null)
                          ? Text(
                              widget.currentName.isNotEmpty
                                  ? widget.currentName[0].toUpperCase()
                                  : 'U',
                              style: AppTypography.heading1
                                  .copyWith(fontSize: 34),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.background, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 13, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              if (_uploading) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Uploading photo…',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textTertiary)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              // ── Display name field ───────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                style: AppTypography.body2,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import 'package:adentweet/core/utils/validators.dart';
import 'package:adentweet/features/auth/data/models/user_model.dart';
import 'package:adentweet/features/profile/presentation/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  File? _newAvatarFile;
  File? _newCoverFile;
  String? _avatarPreview;
  String? _coverPreview;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.profile.displayName;
    _usernameController.text = widget.profile.username;
    _bioController.text = widget.profile.bio ?? '';
    _locationController.text = widget.profile.location ?? '';
    _websiteController.text = widget.profile.website ?? '';
    _avatarPreview = widget.profile.fullAvatarUrl;
    _coverPreview = widget.profile.fullCoverUrl;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _newAvatarFile = File(picked.path);
        _avatarPreview = picked.path;
      });
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1500,
      maxHeight: 500,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _newCoverFile = File(picked.path);
        _coverPreview = picked.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim().toLowerCase();

    // Check username uniqueness (skip if unchanged)
    if (username != widget.profile.username) {
      try {
        final existing = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('username', username)
            .maybeSingle();
        if (existing != null) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('اسم المستخدم مستخدم بالفعل'),
            autoCloseDuration: const Duration(seconds: 3),
          );
          return;
        }
      } catch (e) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('حدث خطأ أثناء التحقق من اسم المستخدم'),
          autoCloseDuration: const Duration(seconds: 3),
        );
        return;
      }
    }

    final editNotifier = ref.read(editProfileProvider.notifier);
    await editNotifier.updateProfile(
      userId: widget.profile.id,
      displayName: _displayNameController.text.trim(),
      username: username,
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      website: _websiteController.text.trim(),
      newAvatarFile: _newAvatarFile,
      newCoverFile: _newCoverFile,
    );

    if (mounted) {
      final state = ref.read(editProfileProvider);
      if (state.isSuccess) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('تم تحديث الملف الشخصي بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );
        Navigator.of(context).pop(true);
        editNotifier.reset();
      } else if (state.error != null) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(state.error!),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilledButton(
                onPressed: editState.isLoading ? null : _saveProfile,
                child: editState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Cover image
                Stack(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: _coverPreview != null && _coverPreview!.isNotEmpty
                          ? (_newCoverFile != null
                              ? Image.file(
                                  File(_coverPreview!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 150,
                                )
                              : CachedNetworkImage(
                                  imageUrl: _coverPreview!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 150,
                                  errorWidget: (context, url, error) =>
                                      Container(height: 150, color: Colors.grey.shade200),
                                ))
                          : Container(
                              height: 150,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: _pickCover,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text('تعديل', style: TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Avatar
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 4,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: _avatarPreview != null && _avatarPreview!.isNotEmpty
                                ? (_newAvatarFile != null
                                    ? CircleAvatar(
                                        radius: 44,
                                        backgroundImage: FileImage(File(_avatarPreview!)),
                                      )
                                    : CircleAvatar(
                                        radius: 44,
                                        backgroundImage: CachedNetworkImageProvider(_avatarPreview!),
                                      ))
                                : const CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, size: 44, color: Colors.white),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Display name
                      TextFormField(
                        controller: _displayNameController,
                        validator: Validators.validateDisplayName,
                        decoration: InputDecoration(
                          labelText: 'الاسم',
                          hintText: 'الاسم المعروض',
                          border: const UnderlineInputBorder(),
                          counterText: '${_displayNameController.text.length}/50',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        maxLength: 50,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        validator: Validators.validateUsername,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          hintText: '@username',
                          border: const UnderlineInputBorder(),
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        maxLength: 20,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 8),

                      // Bio
                      TextFormField(
                        controller: _bioController,
                        validator: Validators.validateBio,
                        decoration: InputDecoration(
                          labelText: 'النبذة التعريفية',
                          hintText: 'نبذة عنك...',
                          border: const UnderlineInputBorder(),
                          alignLabelWithHint: true,
                          counterText: '${_bioController.text.length}/160',
                        ),
                        maxLines: 3,
                        maxLength: 160,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'الموقع',
                          hintText: 'الموقع الجغرافي',
                          border: const UnderlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        maxLength: 50,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),

                      // Website
                      TextFormField(
                        controller: _websiteController,
                        validator: Validators.validateWebsite,
                        decoration: InputDecoration(
                          labelText: 'الموقع الإلكتروني',
                          hintText: 'https://example.com',
                          border: const UnderlineInputBorder(),
                          prefixIcon: const Icon(Icons.link),
                        ),
                        maxLength: 100,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
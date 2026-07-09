class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف لاتيني واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    final trimmed = value.trim().toLowerCase();
    if (trimmed.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (trimmed.length > 20) {
      return 'اسم المستخدم يجب أن لا يتجاوز 20 حرفاً';
    }
    final usernameRegex = RegExp(r'^[a-z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return 'اسم المستخدم يجب أن يحتوي فقط على أحرف إنجليزية صغيرة، أرقام، وشرطة سفلية';
    }
    if (trimmed.startsWith('_') || trimmed.endsWith('_')) {
      return 'اسم المستخدم لا يمكن أن يبدأ أو ينتهي بشرطة سفلية';
    }
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم المعروض مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    if (value.trim().length > 50) {
      return 'الاسم يجب أن لا يتجاوز 50 حرفاً';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  static String? validateTweetContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'محتوى التغريدة مطلوب';
    }
    if (value.length > 500) {
      return 'التغريدة يجب أن لا تتجاوز 500 حرف';
    }
    return null;
  }

  static String? validateBio(String? value) {
    if (value != null && value.length > 160) {
      return 'النبذة يجب أن لا تتجاوز 160 حرفاً';
    }
    return null;
  }

  static String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uriRegex = RegExp(
      r'^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w-\.\/?%&=]*)?$',
    );
    if (!uriRegex.hasMatch(value.trim())) {
      return 'رابط الموقع غير صالح';
    }
    return null;
  }
}
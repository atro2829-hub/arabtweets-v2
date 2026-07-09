import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _checkTheme();
  }

  void _checkTheme() {
    final brightness = MediaQuery.of(context).platformBrightness;
    setState(() {
      _isDarkMode = brightness == Brightness.dark;
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('حدث خطأ أثناء تسجيل الخروج'),
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      }
    }
  }

  void _navigateTo(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Account Section ──
              _buildSectionHeader('الحساب'),
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'تعديل الملف الشخصي',
                onTap: () => _navigateTo('/edit-profile'),
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'الوضع الداكن',
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Notifications Section ──
              _buildSectionHeader('الإشعارات'),
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: 'إشعارات التغريدات',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
              ),
              _buildSettingsTile(
                icon: Icons.people_outline,
                title: 'إشعارات المتابعين',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
              ),
              _buildSettingsTile(
                icon: Icons.mail_outline,
                title: 'إشعارات الرسائل',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                ),
              ),

              const SizedBox(height: 16),

              // ── Privacy Section ──
              _buildSectionHeader('الخصوصية'),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'حساب خاص',
                subtitle: 'المتابِعون المعتمَدون فقط',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                ),
              ),
              _buildSettingsTile(
                icon: Icons.visibility_off_outlined,
                title: 'إخفاء النشاط',
                subtitle: 'إخفاء منشوراتك عن غير المتابعين',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                ),
              ),

              const SizedBox(height: 16),

              // ── About Section ──
              _buildSectionHeader('حول'),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'عن التطبيق',
                onTap: () => _navigateTo('/about'),
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                title: 'شروط الخدمة',
                onTap: () => _navigateTo('/terms'),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'سياسة الخصوصية',
                onTap: () => _navigateTo('/privacy'),
              ),
              _buildSettingsTile(
                icon: Icons.cookie_outlined,
                title: 'سياسة ملفات تعريف الارتباط',
                onTap: () => _navigateTo('/cookies'),
              ),

              const SizedBox(height: 24),

              // ── Sign Out ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Version
              Center(
                child: Text(
                  'الإصدار 2.0.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            )
          : null,
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_left, color: Colors.grey) : null),
      onTap: onTap,
    );
  }
}
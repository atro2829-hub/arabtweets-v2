import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عن التطبيق'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // App icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.flutter_dash,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // App name
              Text(
                AppConstants.appNameAr,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الإصدار 2.0.0',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '${AppConstants.appNameAr} هي منصة تواصل اجتماعي عربية تهدف إلى توفير مساحة آمنة ومريحة للمستخدمين العرب للتعبير عن آرائهم ومشاركة لحظاتهم. نؤمن بأهمية المحتوى العربي ونسعى لبناء مجتمع رقمي عربي متميز.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 24),

              // Info cards
              _buildInfoCard(
                icon: Icons.code,
                title: 'المطور',
                content: 'فريق تطوير ${AppConstants.appNameAr}',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.palette_outlined,
                title: 'التقنيات',
                content: 'Flutter · Supabase · Riverpod',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.language,
                title: 'اللغة',
                content: 'العربية',
              ),
              const SizedBox(height: 32),

              // Footer
              Text(
                '© 2025 ${AppConstants.appName}. جميع الحقوق محفوظة.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
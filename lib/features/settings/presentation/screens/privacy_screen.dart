import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
          centerTitle: true,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سياسة الخصوصية',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'آخر تحديث: يناير 2025',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 24),

              _SectionTitle('١. المعلومات التي نجمعها'),
              _SectionBody(
                'نجمع المعلومات التالية عند استخدامك للخدمة:',
              ),
              _BulletItem('معلومات الحساب: الاسم واسم المستخدم والبريد الإلكتروني'),
              _BulletItem('المحتوى الذي تنشره: التغريدات والصور والفيديوهات'),
              _BulletItem('بيانات الاستخدام: كيفية تفاعلك مع المنصة'),
              _BulletItem('بيانات الجهاز: نوع الجهاز ونظام التشغيل'),
              _BulletItem('بيانات الموقع: البلد والمنطقة الزمنية'),
              const SizedBox(height: 12),

              _SectionTitle('٢. كيف نستخدم المعلومات'),
              _SectionBody(
                'نستخدم معلوماتك للأغراض التالية:',
              ),
              _BulletItem('تقديم الخدمة وتحسينها وتطويرها'),
              _BulletItem('تخصيص تجربة المستخدم وإظهار محتوى ذي صلة'),
              _BulletItem('إرسال الإشعارات والتحديثات المهمة'),
              _BulletItem('حماية أمن المنصة ومنع الانتهاكات'),
              _BulletItem('تحليل أنماط الاستخدام لتحسين الخدمة'),
              const SizedBox(height: 12),

              _SectionTitle('٣. مشاركة المعلومات'),
              _SectionBody(
                'لا نبيع معلوماتك الشخصية لأطراف ثالثة. قد نشارك معلوماتك في الحالات التالية:',
              ),
              _BulletItem('مع موافقتك الصريحة'),
              _BulletItem('للتوافق مع المتطلبات القانونية'),
              _BulletItem('لحماية حقوقنا وسلامة المستخدمين'),
              _BulletItem('مع مزودي الخدمات الذين يساعدون في تشغيل المنصة'),
              const SizedBox(height: 12),

              _SectionTitle('٤. أمن البيانات'),
              _SectionBody(
                'نتخذ إجراءات أمنية مناسبة لحماية معلوماتك الشخصية من الوصول غير المصرح به أو التعديل أو الإفشاء أو الإتلاف. نستخدم تشفير البيانات أثناء النقل والتخزين.',
              ),

              _SectionTitle('٥. الاحتفاظ بالبيانات'),
              _SectionBody(
                'نحتفظ بمعلوماتك طالما كان حسابك نشطاً أو حسب الحاجة لتقديم الخدمة. عند حذف حسابك، يتم حذف بياناتك الشخصية خلال ٣٠ يوماً. قد نحتفظ ببعض البيانات المجهولة لأغراض تحليلية.',
              ),

              _SectionTitle('٦. حقوقك'),
              _SectionBody(
                'لديك الحق في: الوصول إلى بياناتك الشخصية، وتصحيحها، وحذفها، وطلب نسخة منها. يمكنك ممارسة هذه الحقوق من خلال إعدادات الحساب أو التواصل معنا.',
              ),

              _SectionTitle('٧. ملفات تعريف الارتباط'),
              _SectionBody(
                'نستخدم ملفات تعريف الارتباط لتحسين تجربة المستخدم. راجع سياسة ملفات تعريف الارتباط لمزيد من المعلومات.',
              ),

              _SectionTitle('٨. التواصل'),
              _SectionBody(
                'لأي استفسارات حول سياسة الخصوصية، يرجى التواصل معنا عبر: privacy@adentweet.com',
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.7,
          color: Colors.black87,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
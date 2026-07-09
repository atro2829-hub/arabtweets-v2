import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شروط الخدمة'),
          centerTitle: true,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شروط الخدمة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'آخر تحديث: يناير 2025',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 24),

              _SectionTitle('١. قبول الشروط'),
              _SectionBody(
                'باستخدامك لمنصة عدن توييت ("الخدمة")، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي من هذه الشروط، يرجى عدم استخدام الخدمة.',
              ),

              _SectionTitle('٢. إنشاء الحساب'),
              _SectionBody(
                'يجب أن يكون عمرك ١٣ عاماً على الأقل لإنشاء حساب. يجب أن تكون المعلومات التي تقدمها عند التسجيل دقيقة وكاملة ومحدثة. أنت مسؤول عن الحفاظ على سرية كلمة المرور الخاصة بك وعن جميع الأنشطة التي تتم تحت حسابك.',
              ),

              _SectionTitle('٣. المحتوى'),
              _SectionBody(
                'أنت تتحمل المسؤولية الكاملة عن المحتوى الذي تنشره. يُحظر نشر أي محتوى:',
              ),
              _BulletItem('يحتوي على إهانة أو تحريض على الكراهية'),
              _BulletItem('ينتهك حقوق الملكية الفكرية لأي طرف'),
              _BulletItem('يتضمن معلومات شخصية لطرف ثالث دون إذنه'),
              _BulletItem('يحتوي على برامج ضارة أو فيروسات'),
              _BulletItem('يروج للمحتوى الإباحي أو غير القانوني'),
              _BulletItem('يستخدم للاحتيال أو الخداع'),
              const SizedBox(height: 12),

              _SectionTitle('٤. الخصوصية'),
              _SectionBody(
                'تحكم سياسة الخصوصية الخاصة بنا كيفية جمع واستخدام和保护 المعلومات الشخصية. باستخدام الخدمة، فإنك توافق على جمع واستخدام معلوماتك وفقًا لسياسة الخصوصية.',
              ),

              _SectionTitle('٥. إنهاء الحساب'),
              _SectionBody(
                'يحق لنا تعليق أو إنهاء حسابك في أي وقت لانتهاكك لهذه الشروط. يمكنك أيضًا حذف حسابك في أي وقت من خلال إعدادات الحساب.',
              ),

              _SectionTitle('٦. الإعفاء من المسؤولية'),
              _SectionBody(
                'الخدمة مقدمة "كما هي" و"حسب التوفر". لا نضمن أن الخدمة ستكون خالية من الأخطاء أو المقاطعات. لن نكون مسؤولين عن أي أضرار ناتجة عن استخدامك للخدمة.',
              ),

              _SectionTitle('٧. التعديلات'),
              _SectionBody(
                'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية. استمرارك في استخدام الخدمة بعد التعديل يعني موافقتك على الشروط المعدلة.',
              ),

              _SectionTitle('٨. التواصل'),
              _SectionBody(
                'لأي استفسارات بخصوص هذه الشروط، يرجى التواصل معنا عبر البريد الإلكتروني: support@adentweet.com',
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
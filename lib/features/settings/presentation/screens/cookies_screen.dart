import 'package:flutter/material.dart';

class CookiesScreen extends StatelessWidget {
  const CookiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة ملفات تعريف الارتباط'),
          centerTitle: true,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سياسة ملفات تعريف الارتباط',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'آخر تحديث: يناير 2025',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 24),

              _SectionTitle('١. ما هي ملفات تعريف الارتباط؟'),
              _SectionBody(
                'ملفات تعريف الارتباط (الكوكيز) هي ملفات نصية صغيرة يتم تخزينها على جهازك عند زيارة مواقع الويب أو استخدام التطبيقات. تساعد هذه الملفات في تحسين تجربة المستخدم وتوفير معلومات لمالكي الموقع.',
              ),

              _SectionTitle('٢. أنواع ملفات تعريف الارتباط التي نستخدمها'),

              _SubTitle('أ. ملفات تعريف الارتباط الضرورية'),
              _SectionBody(
                'هذه الملفات ضرورية لعمل التطبيق ولا يمكن تعطيلها. تشمل ملفات المصادقة وتسجيل الدخول وتفضيلات اللغة.',
              ),

              _SubTitle('ب. ملفات تعريف الارتباط الوظيفية'),
              _SectionBody(
                'تسمح هذه الملفات بتذكر تفضيلاتك مثل الوضع الداكن وحجم الخط. تساعد في تخصيص تجربتك في التطبيق.',
              ),

              _SubTitle('ج. ملفات تعريف الارتباط التحليلية'),
              _SectionBody(
                'نجمع هذه الملفات لفهم كيفية تفاعل المستخدمين مع التطبيق. تساعدنا في تحسين الخدمة من خلال تحليل أنماط الاستخدام والأداء.',
              ),

              _SubTitle('د. ملفات تعريف الارتباط الإعلانية'),
              _SectionBody(
                'تُستخدم لتقديم إعلانات ذات صلة بك. قد تشارك هذه الملفات مع شركاء الإعلان لتتبع فعالية الحملات الإعلانية.',
              ),

              _SectionTitle('٣. إدارة ملفات تعريف الارتباط'),
              _SectionBody(
                'يمكنك التحكم في ملفات تعريف الارتباط من خلال إعدادات المتصفح أو جهازك. يرجى ملاحظة أن تعطيل بعض ملفات تعريف الارتباط قد يؤثر على وظائف معينة في التطبيق.',
              ),
              _BulletItem('يمكنك حذف جميع ملفات تعريف الارتباط المخزنة على جهازك'),
              _BulletItem('يمكنك تعطيل ملفات تعريف الارتباط من المتصفح'),
              _BulletItem('يمكنك ضبط المتصفح لتنبيهك عند إرسال ملف تعريف ارتباط'),
              const SizedBox(height: 12),

              _SectionTitle('٤. ملفات تعريف الارتباط من أطراف ثالثة'),
              _SectionBody(
                'قد نستخدم خدمات من أطراف ثالثة تضع ملفات تعريف الارتباط الخاصة بها. تشمل هذه الخدمات أدوات التحليل ومنصات المصادقة. لا نتحكم في ملفات تعريف الارتباط الخاصة بهذه الأطراف.',
              ),

              _SectionTitle('٥. تحديث السياسة'),
              _SectionBody(
                'قد نقوم بتحديث هذه السياسة من وقت لآخر. سنقوم بإخطارك بأي تغييرات كبيرة من خلال إشعار في التطبيق. ننصحك بمراجعة هذه السياسة بشكل دوري.',
              ),

              _SectionTitle('٦. التواصل'),
              _SectionBody(
                'إذا كان لديك أي أسئلة حول سياسة ملفات تعريف الارتباط، يرجى التواصل معنا عبر: cookies@adentweet.com',
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
      padding: const EdgeInsets.only(bottom: 8, top: 8),
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

class _SubTitle extends StatelessWidget {
  final String title;
  const _SubTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
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
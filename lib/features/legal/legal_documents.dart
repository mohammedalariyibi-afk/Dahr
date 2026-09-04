/// Starting-policy legal copy (AR + EN). Not law-firm work.
///
/// Web pages in `admin/src/lib/legal.ts` should stay aligned with this file.
library;

class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String updated;
  final String intro;
  final List<LegalSection> sections;

  String get fullText => [
        intro,
        for (final s in sections) '${s.heading}\n${s.body}',
      ].join('\n\n');
}

enum LegalDocumentKind { privacy, terms }

/// Operator and product facts used in the policy text.
abstract final class LegalFacts {
  static const String product = 'Dahr';
  static const String productAr = 'دهر';
  static const String operator = 'Mohammed Alariyibi';
  static const String operatorAr = 'محمد العريبي';
  static const String contactEmail = 'mohammedalariyibi@gmail.com';
  static const String region = 'eu-west-1';
  static const String backendName = 'Dahr LY';
  static const String updatedIso = '2026-09-04';
  static const String startingPolicyEn =
      'This is a starting privacy notice for the Dahr marketplace. It is not legal advice.';
  static const String startingPolicyAr =
      'هذا بيان خصوصية أوّلي لتطبيق دهر. وهو ليس استشارة قانونية.';
}

abstract final class LegalDocuments {
  static LegalDocument of(LegalDocumentKind kind, String languageCode) {
    final ar = languageCode == 'ar';
    switch (kind) {
      case LegalDocumentKind.privacy:
        return ar ? privacyAr : privacyEn;
      case LegalDocumentKind.terms:
        return ar ? termsAr : termsEn;
    }
  }

  static const LegalDocument privacyEn = LegalDocument(
    title: 'Privacy policy',
    updated: 'Last updated: 4 September 2026',
    intro:
        '${LegalFacts.startingPolicyEn} Dahr is a wedding vendor marketplace for Libya, operated by ${LegalFacts.operator}. Contact: ${LegalFacts.contactEmail}.',
    sections: [
      LegalSection(
        heading: 'Who we are',
        body:
            'Dahr helps couples in Libya browse wedding vendors, request bookings, and leave a review after a booking is marked complete. Vendors can list a business, upload photos, and receive requests. The live backend is the ${LegalFacts.backendName} Supabase project in region ${LegalFacts.region} (Ireland, EU).',
      ),
      LegalSection(
        heading: 'Accounts and sign-in',
        body:
            'You can browse Discover as a guest. Creating an account uses a one-time code (OTP) sent to your email address. Phone OTP is not used. We store the account id and email from sign-in, the name and city you enter, optional wedding date, language (Arabic or English), whether you use Dahr as a couple or a vendor, and a mobile number you may add so the vendor of a booking can WhatsApp you. We do not use passwords in the consumer app. Vendors may also store a WhatsApp number on their listing. The couple mobile number is not used to sign in and is not shown on Discover.',
      ),
      LegalSection(
        heading: 'Vendor listings and photos',
        body:
            'If you onboard as a vendor we store business name, category, city, description, price range in LYD, WhatsApp number, services, and approval or verification flags. Photos you upload go to Supabase Storage (bucket vendor-photos) under your account id. Public listing photos are visible to anyone using Dahr once an admin approves the listing.',
      ),
      LegalSection(
        heading: 'Bookings, messages, and reviews',
        body:
            'A booking request stores the event date, optional guest count, and the message you send the vendor. Vendors may add a quoted amount in LYD when they accept. After a booking is marked complete, the couple may leave a rating and comment. Reports you submit (reason + target) are stored so we can moderate.',
      ),
      LegalSection(
        heading: 'WhatsApp leaves the app',
        body:
            'Contacting a vendor opens WhatsApp (wa.me) with the number on their listing. A vendor who has a booking with you can also open WhatsApp with the mobile number on your profile. WhatsApp messages are not stored in Dahr. WhatsApp is operated by a third party with its own terms and privacy policy. Anything you type there is outside Dahr.',
      ),
      LegalSection(
        heading: 'Payments and cards',
        body:
            'Couples pay vendors the rest of the quote off-platform (often via WhatsApp or in person). Couples pay Dahr a 10% platform fee by online bank transfer. Dahr does not process card payments and does not store card numbers, CVVs, or payment-provider tokens. There is no Stripe, Apple IAP, or Google Play Billing in this app. We record the 10% fee on accepted quotes (amount in LYD and unpaid/paid/waived status) so the operator can confirm the bank transfer.',
      ),
      LegalSection(
        heading: 'Analytics and tracking',
        body:
            'Dahr does not include advertising SDKs, crash reporters, or third-party analytics packages in the app. We do not invent extra trackers here. The backend and hosting (Supabase) keep ordinary operational logs (for example sign-in, storage access, and security) needed to run the service. Vendor profiles store a simple view count when someone opens an approved listing.',
      ),
      LegalSection(
        heading: 'Where data is stored',
        body:
            'Account and marketplace data is stored in Postgres and Storage on Supabase in ${LegalFacts.region}. That is an EU region. If you use Dahr from Libya, your data is still hosted there. We do not sell your personal data.',
      ),
      LegalSection(
        heading: 'How long we keep data',
        body:
            'We keep account, listing, booking, review, and commission records while the account exists and as needed to operate the marketplace (including unpaid commission). Deleted accounts are removed as described below. We may keep limited records if the law requires it or to resolve a dispute.',
      ),
      LegalSection(
        heading: 'Delete your account',
        body:
            'Signed-in users can delete their account in the app: Profile → Delete account, then confirm. You do not need to contact support. Deletion removes the auth user; the profile cascades, so a vendor listing, photos metadata, availability, related bookings, reviews, and favorites are removed as the database foreign keys allow. Storage photo files for that account are removed as part of deletion. If in-app deletion fails, email ${LegalFacts.contactEmail} from the same email as the account and ask us to delete it. We will only delete the account that matches that identity — we will not delete someone else’s account on request without being able to verify it.',
      ),
      LegalSection(
        heading: 'Your choices',
        body:
            'You can use Dahr as a guest for discovery. You can change language in Profile (we also save that language on your account when you are signed in). You can sign out without deleting the account. You can edit your name, city, wedding date, and mobile number from Profile. You can edit a vendor listing and delete individual photos while the account exists.',
      ),
      LegalSection(
        heading: 'Children',
        body:
            'Dahr is meant for adults arranging a wedding, not for children. Do not create an account if you are not old enough to contract in your country.',
      ),
      LegalSection(
        heading: 'Changes',
        body:
            'We may update this notice as Dahr changes. The in-app screen and the public web page will show a new “last updated” date. Continued use after an update means you have read the new notice.',
      ),
      LegalSection(
        heading: 'Contact',
        body:
            'Operator: ${LegalFacts.operator}. Email: ${LegalFacts.contactEmail}. Product: Dahr (${LegalFacts.backendName}).',
      ),
    ],
  );

  static const LegalDocument termsEn = LegalDocument(
    title: 'Terms of use',
    updated: 'Last updated: 4 September 2026',
    intro:
        '${LegalFacts.startingPolicyEn} These terms are a simple description of how Dahr works today. They are not a substitute for a lawyer-drafted contract.',
    sections: [
      LegalSection(
        heading: 'The service',
        body:
            'Dahr is a marketplace for couples and wedding vendors in Libya (starting with Tripoli and Benghazi). Couples browse vendors, request a booking, and may review after the vendor marks the booking complete. Vendors create a listing, upload photos, manage dates, and respond to requests. Dahr is operated by ${LegalFacts.operator}.',
      ),
      LegalSection(
        heading: 'Accounts',
        body:
            'You are responsible for the email you use to sign in. Keep OTP codes private. One person per account. Do not impersonate another vendor or couple. We may suspend accounts that abuse the service or submit false listings.',
      ),
      LegalSection(
        heading: 'Couples',
        body:
            'A booking request is a message to the vendor, not a guaranteed reservation until the vendor accepts. You pay the vendor the rest of the quote directly off-platform. You pay Dahr the 10% platform fee by online bank transfer. Dahr is not a party to the vendor payment and does not hold customer funds or process cards.',
      ),
      LegalSection(
        heading: 'Vendors',
        body:
            'Listings are not public until an admin approves them. You must only upload photos you have the right to use. WhatsApp numbers on the listing should be a number you monitor. Quoted amounts must be in LYD and should match what you agreed with the couple.',
      ),
      LegalSection(
        heading: 'Commission',
        body:
            'When a vendor accepts a request they enter a quote in LYD. Dahr records 10% of that quote as the platform fee the couple pays to Dahr by bank transfer. The rest of the quote is settled with the vendor off-platform. Completing a booking does not mark the fee paid. Admins record paid or waived after the transfer is confirmed. Couples can send a transfer reference note; they cannot mark the fee paid themselves.',
      ),
      LegalSection(
        heading: 'No in-app payments',
        body:
            'Dahr does not take card payments. There is no payment SDK. Any money that changes hands between couple and vendor, or couple and Dahr, happens outside the app.',
      ),
      LegalSection(
        heading: 'WhatsApp',
        body:
            'The WhatsApp button opens a third-party app. Dahr is not responsible for WhatsApp conversations, scams that occur there, or WhatsApp account bans.',
      ),
      LegalSection(
        heading: 'Content',
        body:
            'You keep the rights to your photos and text. You grant Dahr a licence to host and display them so the marketplace can function. We may hide reviews or listings after a report. Do not post illegal content, hate, or someone else’s photos without permission.',
      ),
      LegalSection(
        heading: 'Availability',
        body:
            'Dahr is provided as-is. We may change features, take the app down for maintenance, or refuse a listing. We do not guarantee that a vendor will accept a date or that a wedding will go as planned.',
      ),
      LegalSection(
        heading: 'Liability',
        body:
            'Vendors supply their own services. Disputes about quality, refunds, or dates are between the couple and the vendor. To the extent allowed by law, Dahr and ${LegalFacts.operator} are not liable for off-platform payments, WhatsApp messages, or vendor performance.',
      ),
      LegalSection(
        heading: 'Account deletion',
        body:
            'You may delete your account in Profile without calling support. Vendor listings and photos are removed as the database allows. Email ${LegalFacts.contactEmail} if in-app deletion does not work. See the privacy policy for what is deleted.',
      ),
      LegalSection(
        heading: 'Governing law',
        body:
            'Dahr is operated for users in Libya. These terms are intended to be read under Libyan law, without affecting any consumer rights you cannot waive. EU hosting (${LegalFacts.region}) does not by itself make Dahr an EU consumer service.',
      ),
      LegalSection(
        heading: 'Contact',
        body:
            'Questions: ${LegalFacts.contactEmail}. Operator: ${LegalFacts.operator}.',
      ),
    ],
  );

  static const LegalDocument privacyAr = LegalDocument(
    title: 'سياسة الخصوصية',
    updated: 'آخر تحديث: 4 سبتمبر 2026',
    intro:
        '${LegalFacts.startingPolicyAr} دهر سوق لمورّدي الزفاف في ليبيا، يشغّله ${LegalFacts.operatorAr}. للتواصل: ${LegalFacts.contactEmail}.',
    sections: [
      LegalSection(
        heading: 'من نحن',
        body:
            'يساعد دهر الأزواج في ليبيا على تصفح مورّدي الزفاف، وطلب حجز، وترك تقييم بعد تعليم الحجز مكتملاً. يمكن للمورّد عرض نشاطه ورفع صور واستقبال الطلبات. الخلفية التشغيلية هي مشروع ${LegalFacts.backendName} على Supabase في المنطقة ${LegalFacts.region} (أيرلندا، الاتحاد الأوروبي).',
      ),
      LegalSection(
        heading: 'الحسابات وتسجيل الدخول',
        body:
            'يمكنك تصفح الاكتشاف كزائر. إنشاء حساب يتم برمز لمرة واحدة (OTP) يُرسل إلى بريدك الإلكتروني. لا نستخدم رمز هاتف لتسجيل الدخول. نخزّن معرّف الحساب والبريد من تسجيل الدخول، والاسم والمدينة التي تدخلها، وتاريخ الزفاف الاختياري، واللغة (العربية أو الإنجليزية)، وما إذا كنت تستخدم دهر كزوجين أو كمورّد، ورقم جوّال قد تضيفه حتى يتواصل مورّد الحجز معك عبر واتساب. لا نستخدم كلمات مرور في تطبيق الأزواج/المورّدين. قد يخزّن المورّد أيضاً رقم واتساب في عرضه. رقم جوّال الزوجين لا يُستخدم لتسجيل الدخول ولا يظهر في الاكتشاف.',
      ),
      LegalSection(
        heading: 'عروض المورّدين والصور',
        body:
            'إذا سجّلت كمورّد نخزّن اسم النشاط، والتصنيف، والمدينة، والوصف، ونطاق السعر بالدينار الليبي، ورقم واتساب، والخدمات، وعلامات الموافقة أو التوثيق. الصور تُرفع إلى تخزين Supabase (حاوية vendor-photos) تحت معرّف حسابك. صور العرض تصبح ظاهرة لأي مستخدم لدهر بعد موافقة الإدارة.',
      ),
      LegalSection(
        heading: 'الحجوزات والرسائل والتقييمات',
        body:
            'طلب الحجز يخزّن تاريخ المناسبة، وعدد الضيوف الاختياري، والرسالة التي ترسلها للمورّد. قد يضيف المورّد مبلغاً متفقاً عليه بالدينار عند القبول. بعد تعليم الحجز مكتملاً يمكن للزوجين ترك تقييم وتعليق. البلاغات (السبب والهدف) تُحفظ للمراجعة.',
      ),
      LegalSection(
        heading: 'واتساب خارج التطبيق',
        body:
            'التواصل مع المورّد يفتح واتساب (wa.me) بالرقم الظاهر في عرضه. مورّد لديه حجز معك يمكنه أيضاً فتح واتساب برقم الجوّال في ملفك. رسائل واتساب لا تُحفظ في دهر. واتساب خدمة طرف ثالث لها شروطها وسياسة خصوصيتها. أي شيء تكتبه هناك خارج دهر.',
      ),
      LegalSection(
        heading: 'المدفوعات والبطاقات',
        body:
            'يدفع الأزواج بقية عرض السعر للمورّد خارج المنصة (غالباً عبر واتساب أو مباشرة). يدفع الأزواج لدهر رسوم منصة 10٪ بتحويل بنكي عبر الإنترنت. دهر لا يعالج مدفوعات البطاقات ولا يخزّن أرقام بطاقات أو رموز CVV أو رموز مزوّد دفع. لا يوجد Stripe أو مشتريات داخل تطبيق آبل أو فوترة Google Play. نسجّل رسوم 10٪ على العروض المقبولة (المبلغ بالدينار وحالة غير مدفوعة/مدفوعة/معفاة) حتى يؤكّد المشغّل التحويل البنكي.',
      ),
      LegalSection(
        heading: 'التحليلات والتتبع',
        body:
            'لا يتضمّن دهر حزم إعلانات أو أدوات بلاغ أعطال أو تحليلات طرف ثالث في التطبيق. لا نخترع أدوات تتبع إضافية هنا. تحتفظ الخلفية والاستضافة (Supabase) بسجلات تشغيل عادية (مثل تسجيل الدخول والوصول إلى التخزين والأمان) لتشغيل الخدمة. تخزّن ملفات المورّدين عدّاد مشاهدات بسيط عند فتح عرض موافق عليه.',
      ),
      LegalSection(
        heading: 'أين تُحفظ البيانات',
        body:
            'تُحفظ بيانات الحساب والسوق في Postgres والتخزين على Supabase في ${LegalFacts.region}. هذه منطقة داخل الاتحاد الأوروبي. إذا استخدمت دهر من ليبيا فما زالت البيانات تُستضاف هناك. لا نبيع بياناتك الشخصية.',
      ),
      LegalSection(
        heading: 'مدة الاحتفاظ',
        body:
            'نحتفظ بسجلات الحساب والعرض والحجز والتقييم والعمولة طالما الحساب موجود وكما يلزم لتشغيل السوق (بما في ذلك العمولة غير المدفوعة). تُحذف الحسابات كما هو موضح أدناه. قد نحتفظ بسجلات محدودة إذا تطلب القانون ذلك أو لحل نزاع.',
      ),
      LegalSection(
        heading: 'حذف حسابك',
        body:
            'يمكن للمستخدم المسجّل حذف حسابه من التطبيق: حسابي ← حذف الحساب، ثم التأكيد. لا تحتاج إلى التواصل مع الدعم. الحذف يزيل مستخدم المصادقة؛ ويتبعه الملف الشخصي، فيُحذف عرض المورّد وبيانات الصور والتوفر والحجوزات المرتبطة والتقييمات والمفضلة حسب مفاتيح قاعدة البيانات. تُحذف ملفات الصور في التخزين ضمن عملية الحذف. إذا فشل الحذف من التطبيق راسل ${LegalFacts.contactEmail} من نفس البريد المرتبط بالحساب واطلب الحذف. لن نحذف حساب شخص آخر دون التمكّن من التحقق من الهوية.',
      ),
      LegalSection(
        heading: 'خياراتك',
        body:
            'يمكنك استخدام دهر كزائر للاكتشاف. يمكنك تغيير اللغة من حسابي (ونحفظ تلك اللغة على حسابك عندما تكون مسجّلاً). يمكنك تسجيل الخروج دون حذف الحساب. يمكنك تعديل الاسم والمدينة وتاريخ الزفاف ورقم الجوّال من حسابي. يمكنك تعديل عرض المورّد وحذف صور منفردة طالما الحساب موجود.',
      ),
      LegalSection(
        heading: 'الأطفال',
        body:
            'دهر موجّه للبالغين الذين ينظّمون زفافاً، وليس للأطفال. لا تنشئ حساباً إن لم تكن في سن تؤهلك للتعاقد في بلدك.',
      ),
      LegalSection(
        heading: 'التغييرات',
        body:
            'قد نحدّث هذا البيان مع تغيّر دهر. ستظهر شاشة التطبيق والصفحة العلنية تاريخ «آخر تحديث» جديد. استمرار الاستخدام بعد التحديث يعني أنك اطّلعت على البيان الجديد.',
      ),
      LegalSection(
        heading: 'التواصل',
        body:
            'المشغّل: ${LegalFacts.operatorAr}. البريد: ${LegalFacts.contactEmail}. المنتج: دهر (${LegalFacts.backendName}).',
      ),
    ],
  );

  static const LegalDocument termsAr = LegalDocument(
    title: 'شروط الاستخدام',
    updated: 'آخر تحديث: 4 سبتمبر 2026',
    intro:
        '${LegalFacts.startingPolicyAr} هذه الشروط وصف مبسّط لكيفية عمل دهر اليوم، وليست بديلاً عن عقد يصوغه محامٍ.',
    sections: [
      LegalSection(
        heading: 'الخدمة',
        body:
            'دهر سوق للأزواج ومورّدي الزفاف في ليبيا (بدايةً طرابلس وبنغازي). يتصفح الأزواج المورّدين ويطلبون حجزاً وقد يقيّمون بعد أن يعلّم المورّد الحجز مكتملاً. ينشئ المورّد عرضاً ويرفع صوراً ويدير التواريخ ويرد على الطلبات. يشغّل دهر ${LegalFacts.operatorAr}.',
      ),
      LegalSection(
        heading: 'الحسابات',
        body:
            'أنت مسؤول عن البريد الإلكتروني الذي تستخدمه لتسجيل الدخول. احتفظ برموز OTP لنفسك. حساب واحد لكل شخص. لا تنتحل صفة مورّد أو زوجين آخرين. قد نعلّق الحسابات التي تسيء استخدام الخدمة أو تقدّم عروضاً غير صحيحة.',
      ),
      LegalSection(
        heading: 'الأزواج',
        body:
            'طلب الحجز رسالة إلى المورّد وليس حجزاً مضموناً حتى يقبل المورّد. تدفع بقية عرض السعر للمورّد مباشرة خارج المنصة. تدفع رسوم منصة دهر 10٪ بتحويل بنكي عبر الإنترنت. دهر ليس طرفاً في دفع المورّد ولا يحتفظ بأموال العملاء ولا يعالج البطاقات.',
      ),
      LegalSection(
        heading: 'المورّدون',
        body:
            'العروض لا تظهر للعامة حتى توافق الإدارة. ارفع فقط صوراً تملك حق استخدامها. يجب أن يكون رقم واتساب في العرض رقماً تتابعه. المبالغ المتفق عليها بالدينار الليبي وينبغي أن تطابق ما اتفقتم عليه مع الزوجين.',
      ),
      LegalSection(
        heading: 'العمولة',
        body:
            'عند قبول طلب يدخل المورّد عرض سعر بالدينار. يسجّل دهر 10٪ من ذلك المبلغ كرسوم منصة يدفعها الزوجان لدهر بتحويل بنكي. بقية المبلغ تُسوّى مع المورّد خارج المنصة. إكمال الحجز لا يعلّم الرسوم مدفوعة. تسجّل الإدارة المدفوع أو المعفى بعد تأكيد التحويل. يمكن للزوجين إرسال ملاحظة مرجع التحويل؛ ولا يمكنهم تعليم الرسوم مدفوعة بأنفسهم.',
      ),
      LegalSection(
        heading: 'لا مدفوعات داخل التطبيق',
        body:
            'دهر لا يستقبل مدفوعات بطاقات. لا توجد حزمة دفع. أي مال بين الزوجين والمورّد، أو الزوجين ودهر، يتم خارج التطبيق.',
      ),
      LegalSection(
        heading: 'واتساب',
        body:
            'زر واتساب يفتح تطبيقاً لطرف ثالث. دهر غير مسؤول عن محادثات واتساب أو الاحتيال الذي يحدث هناك أو حظر حساب واتساب.',
      ),
      LegalSection(
        heading: 'المحتوى',
        body:
            'تحتفظ بحقوق صورك ونصوصك. تمنح دهر ترخيصاً لاستضافتها وعرضها ليعمل السوق. قد نخفي تقييمات أو عروضاً بعد بلاغ. لا تنشر محتوى غير قانوني أو كراهية أو صور غيرك دون إذن.',
      ),
      LegalSection(
        heading: 'التوفر',
        body:
            'يُقدَّم دهر كما هو. قد نغيّر الميزات أو نوقف التطبيق للصيانة أو نرفض عرضاً. لا نضمن أن يقبل المورّد تاريخاً أو أن يسير الزفاف كما خُطط.',
      ),
      LegalSection(
        heading: 'المسؤولية',
        body:
            'المورّدون يقدّمون خدماتهم بأنفسهم. النزاعات حول الجودة أو الاسترجاع أو التواريخ بين الزوجين والمورّد. في حدود ما يسمح به القانون، دهر و${LegalFacts.operatorAr} غير مسؤولين عن المدفوعات خارج المنصة أو رسائل واتساب أو أداء المورّد.',
      ),
      LegalSection(
        heading: 'حذف الحساب',
        body:
            'يمكنك حذف حسابك من «حسابي» دون التواصل مع الدعم. تُزال عروض المورّد والصور حسب ما تسمح به قاعدة البيانات. راسل ${LegalFacts.contactEmail} إذا لم يعمل الحذف من التطبيق. راجع سياسة الخصوصية لمعرفة ما يُحذف.',
      ),
      LegalSection(
        heading: 'القانون الواجب التطبيق',
        body:
            'يُشغَّل دهر لمستخدمين في ليبيا. يُقصد قراءة هذه الشروط وفق القانون الليبي، دون المساس بأي حقوق مستهلك لا يمكن التنازل عنها. الاستضافة في الاتحاد الأوروبي (${LegalFacts.region}) لا تجعل دهر بحد ذاتها خدمة مستهلك أوروبية.',
      ),
      LegalSection(
        heading: 'التواصل',
        body:
            'للأسئلة: ${LegalFacts.contactEmail}. المشغّل: ${LegalFacts.operatorAr}.',
      ),
    ],
  );
}

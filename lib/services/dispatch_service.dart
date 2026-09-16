import 'package:url_launcher/url_launcher.dart';
import '../models/lead.dart';

/// Universal RFC-compliant dispatch service for WhatsApp, Email, and Web preview.
/// Strictly eliminates unwanted '+' signs, preserving clean paragraphs, bullet points,
/// and spaces across all WhatsApp clients and native mail applications.
class DispatchService {
  /// Safe Percent-Encoding preserving spaces as %20 and newlines as %0A (Strictly Zero '+' signs)
  static String encodeParam(String text) {
    return Uri.encodeComponent(text).replaceAll('+', '%20');
  }

  /// 1. WhatsApp Dispatcher (RFC-compliant encoding, Zero '+' signs)
  static Future<bool> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = sanitizePhoneNumber(phone);
    final encoded = encodeParam(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      final fallbackUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
      return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Helper for direct Lead WhatsApp dispatch
  static Future<bool> launchWhatsAppOutreach({
    required Lead lead,
    bool preferArabic = true,
  }) async {
    final message = generateWhatsAppCopy(lead: lead, preferArabic: preferArabic);
    return await launchWhatsApp(phone: lead.phone, message: message);
  }

  /// 2. Email Dispatcher (RFC-compliant encoding, Zero '+' signs)
  static Future<bool> launchEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${encodeParam(subject)}&body=${encodeParam(body)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Helper for direct Lead Email pitch
  static Future<bool> launchEmailPitch({required Lead lead}) async {
    final subject = generateEmailSubject(lead: lead);
    final body = generateEmailBody(lead: lead);
    return await launchEmail(email: lead.email, subject: subject, body: body);
  }

  /// Opens Website preview in external browser
  static Future<bool> launchWebsitePreview(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final uri = Uri.tryParse(formattedUrl);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Sends the polite apology via WhatsApp to an unassigned contact before archiving
  static Future<bool> launchApologyWhatsApp({
    required String phone,
    required String apologyText,
  }) async {
    return await launchWhatsApp(phone: phone, message: apologyText);
  }

  /// Sanitizes phone number to international MENA format digits only
  static String sanitizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// 100% human-written, conversational, peer-level WhatsApp copy
  /// Tailored for Saudi/GCC decision-makers (Zero robotic fluff)
  static String generateWhatsAppCopy({
    required Lead lead,
    required bool preferArabic,
  }) {
    if (preferArabic) {
      final nameGreeting = lead.contactName.isNotEmpty
          ? 'أخوي ${lead.contactName}'
          : 'فريق ${lead.companyName}';

      return '''هلا والله $nameGreeting، مساك الله بالخير.

كنت مار على موقعكم (${lead.websiteUrl}) خلال مراجعة شركات ${lead.corridor}، ولاحظت شغلة دقيقة قاعدة تضيع عليكم عملاء يومياً:
👉 ${lead.marketingGap} ${lead.marketingGapDetails.isNotEmpty ? "(${lead.marketingGapDetails})" : ""}

إحنا شغالين مع شركات في الرياض والخليج بنموذج نمو ريموت مرن وسريع (Cross-Border Growth Sprints) بدون هدر وتكاليف الوكالات التقليدية، وتركيزنا مباشر على مضاعفة الـ ROAS واستقطاب عملاء فعليين جاهزين للتعاقد.

ما بطول عليك، هل يناسبك اتصال سريع 10 دقائق على زووم هذا الأسبوع أوريك الخطة المجانية؟''';
    } else {
      final nameGreeting = lead.contactName.isNotEmpty ? lead.contactName : "there";

      return '''Hey $nameGreeting,

Was checking out companies around ${lead.corridor} today and took a look at ${lead.companyName} (${lead.websiteUrl}).

Noticed an immediate acquisition leak on your setup:
👉 ${lead.marketingGap} ${lead.marketingGapDetails.isNotEmpty ? "(${lead.marketingGapDetails})" : ""}

Basically, high-intent traffic across ${lead.country} is visiting without proper tracking or retargeting funnels.

We run lean, cross-border remote growth sprints for GCC brands — strictly performance-driven with zero agency bloat.

Open to a brief 10-minute Zoom walkthrough this Wednesday to show you the fix?''';
    }
  }

  /// 100% human-written, peer-level cold email subject
  static String generateEmailSubject({required Lead lead}) {
    return 'Quick observation on ${lead.companyName}\'s acquisition funnel (${lead.corridor})';
  }

  /// 100% human-written, conversational, peer-level cold proposal body
  static String generateEmailBody({required Lead lead}) {
    final contactGreeting = lead.contactName.isNotEmpty ? lead.contactName : "there";

    return '''Hi $contactGreeting,

I was reviewing digital conversion setups for businesses in ${lead.corridor}, ${lead.country} and came across ${lead.companyName}.

I spotted a clear performance bottleneck that’s likely leaking qualified revenue:
• Bottleneck: ${lead.marketingGap}
• Detail: ${lead.marketingGapDetails.isNotEmpty ? lead.marketingGapDetails : "Traffic is landing but dropping off without automated retargeting or tracking."}

How we operate differently:
Rather than standard bloated retainers, we run agile, remote performance sprints with senior acquisition strategists across the GCC. We step in, implement the tracking and high-converting funnels, and prove ROI within 30 days.

Remote Collaboration Highlights:
• Live performance telemetry & dashboard
• Zero wasted overhead — 100% focused on ROAS
• Fast execution with cross-border GCC agility

Do you have 10 minutes this Wednesday or Thursday for a quick, no-pitch Zoom call? I’d be glad to share a tailored 1-page roadmap.

Best,

Head of Growth | MENA Performance Group''';
  }
}

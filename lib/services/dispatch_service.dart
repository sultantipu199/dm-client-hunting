import 'package:url_launcher/url_launcher.dart';
import '../models/lead.dart';

/// Handles 1-tap outbound dispatching across WhatsApp, Email, and Website previews.
class DispatchService {
  /// Launches WhatsApp with high-converting, tailored Arabic or English growth copy.
  static Future<bool> launchWhatsAppOutreach({
    required Lead lead,
    bool preferArabic = true,
  }) async {
    // 1. Sanitize phone number (strip whitespace, dashes, plus sign for WhatsApp API)
    final cleanPhone = sanitizePhoneNumber(lead.phone);
    final message = generateWhatsAppCopy(lead: lead, preferArabic: preferArabic);

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      return await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback intent if universal link fails
      final fallbackUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedMessage');
      return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Launches Native Mail Client via mailto: with pre-filled subject and executive proposal body.
  static Future<bool> launchEmailPitch({required Lead lead}) async {
    final subject = generateEmailSubject(lead: lead);
    final body = generateEmailBody(lead: lead);

    final mailtoUri = Uri(
      scheme: 'mailto',
      path: lead.email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      return await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens Website preview in external browser or in-app view
  static Future<bool> launchWebsitePreview(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final uri = Uri.tryParse(formattedUrl);
    if (uri != null) {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Sends the official polite apology via WhatsApp to an unassigned contact before archiving
  static Future<bool> launchApologyWhatsApp({
    required String phone,
    required String apologyText,
  }) async {
    final cleanPhone = sanitizePhoneNumber(phone);
    final encoded = Uri.encodeComponent(apologyText);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Sanitizes phone number to international MENA format digits only
  static String sanitizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  /// Generates high-converting WhatsApp message tailored to marketing gap, location, and remote agility
  static String generateWhatsAppCopy({
    required Lead lead,
    required bool preferArabic,
  }) {
    if (preferArabic) {
      return '''السلام عليكم ورحمة الله،
تحياتي لفريق ${lead.companyName} (${lead.corridor}).

لاحظنا خلال تدقيق تسويقي سريع لموقعكم أن هناك فرصة نمو استثنائية لم تُستغل بعد:
[ ${lead.marketingGap} ] ${lead.marketingGapDetails.isNotEmpty ? "- ${lead.marketingGapDetails}" : ""}

نحن وكالة نمو رقمي متخصصة في أسواق الشرق الأوسط، ونقدم نموذج عمل مرن وعن بُعد (Cross-Border Growth Sprints) يحقق لعملائنا في ${lead.country} أسرع عائد على الإنفاق الإعلاني (ROAS) وبأقل تكلفة استحواذ.

هل يناسبكم اتصال سريع مدته 10 دقائق هذا الأسبوع لاستعراض خارطة طريق مجانية تضاعف وصولكم لعملائكم المستهدفين؟''';
    } else {
      return '''Hello ${lead.contactName.isNotEmpty ? lead.contactName : "Team ${lead.companyName}"},

We conducted a brief digital acquisition audit for ${lead.companyName} in ${lead.corridor} and spotted a critical growth bottleneck:
[ ${lead.marketingGap} ] ${lead.marketingGapDetails.isNotEmpty ? "- ${lead.marketingGapDetails}" : ""}

Our MENA-wide growth agency provides remote, cross-border digital acquisition sprints with proven high-ROAS funnels across ${lead.country}.

Would you be open to a 10-minute discovery call this week to review our complimentary audit roadmap?''';
    }
  }

  /// Pre-filled email subject line
  static String generateEmailSubject({required Lead lead}) {
    return 'Strategic Acquisition Audit: Growth Roadmap for ${lead.companyName} (${lead.marketingGap})';
  }

  /// Pre-filled email pitch body
  static String generateEmailBody({required Lead lead}) {
    return '''Dear ${lead.contactName.isNotEmpty ? lead.contactName : "Executive Leadership"},

I hope this email finds you well at ${lead.companyName}.

Our agency performance team recently analyzed digital presence across key commercial hubs in ${lead.corridor}, ${lead.country}. We noticed a major untapped opportunity regarding your digital marketing architecture:

Detected Gap: ${lead.marketingGap}
Audit Detail: ${lead.marketingGapDetails.isNotEmpty ? lead.marketingGapDetails : "Underutilized conversion funnels and acquisition tracking."}

How We Help:
We deliver high-impact, MENA remote growth sprints. Because our model operates remotely with senior acquisition talent across the GCC and broader Middle East, we eliminate traditional agency bloat and deliver 2x-3x higher ROAS within 30 days.

Validated Collaboration:
- Agreement: Full cross-border remote execution with weekly strategic sprints.
- Transparency: Live performance dashboards, dedicated Slack/WhatsApp channel, and bi-weekly executive reviews.

Would you be available for a brief 10-minute Zoom or Google Meet walkthrough this Wednesday or Thursday?

Best regards,

Growth Partnerships Director
MENA Digital Acquisition Group''';
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dm_client_hunting/models/lead.dart';
import 'package:dm_client_hunting/services/dispatch_service.dart';
import 'package:dm_client_hunting/services/gemini_service.dart';
import 'package:dm_client_hunting/services/storage_service.dart';

void main() {
  group('Lead & Acquisition Engine Tests', () {
    test('Lead model serializes and deserializes correctly', () {
      final lead = Lead(
        id: 'test_01',
        companyName: 'KAFD Capital Partners',
        websiteUrl: 'https://kafdcapital.sa',
        country: 'Saudi Arabia (KSA)',
        corridor: 'KAFD Phase 1 & 2',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '+966501234567',
        email: 'info@kafdcapital.sa',
        createdAt: DateTime.now(),
      );

      final json = lead.toJson();
      final fromJson = Lead.fromJson(json);

      expect(fromJson.id, lead.id);
      expect(fromJson.companyName, lead.companyName);
      expect(fromJson.corridor, lead.corridor);
      expect(fromJson.agreesToRemoteWork, true);
    });

    test('Universal RFC-compliant encoding strictly eliminates + signs', () {
      final encodedSpace = DispatchService.encodeParam('Hello World');
      expect(encodedSpace, 'Hello%20World');
      expect(encodedSpace.contains('+'), false);

      const multiline = 'Line 1\nLine 2 with spaces & bullets: • Item';
      final encodedMultiline = DispatchService.encodeParam(multiline);
      expect(encodedMultiline.contains('+'), false);
      expect(encodedMultiline.contains('%20'), true);
      expect(encodedMultiline.contains('%0A'), true);
    });

    test('DispatchService sanitizes phone numbers for WhatsApp API', () {
      expect(DispatchService.sanitizePhoneNumber('+966 50 123 4567'), '966501234567');
      expect(DispatchService.sanitizePhoneNumber('+971-50-987-6543'), '971509876543');
      expect(DispatchService.sanitizePhoneNumber('00966501234567'), '00966501234567');
    });

    test('Humanized conversational copy generation includes gap and remote sprint', () {
      final lead = Lead(
        id: 'test_02',
        companyName: 'Dubai Luxury Realty',
        websiteUrl: 'https://dubailuxury.ae',
        country: 'United Arab Emirates (UAE)',
        corridor: 'DIFC Financial Centre (Dubai)',
        sector: 'Luxury Real Estate Agencies',
        marketingGap: '⚡ Low Google Visibility / No Search Ads',
        marketingGapDetails: 'No Google search rank for prime villas',
        phone: '+971501239841',
        email: 'info@dubailuxury.ae',
        createdAt: DateTime.now(),
      );

      final arabicMsg = DispatchService.generateWhatsAppCopy(lead: lead, preferArabic: true);
      final englishMsg = DispatchService.generateWhatsAppCopy(lead: lead, preferArabic: false);

      expect(arabicMsg.contains('Dubai Luxury Realty'), true);
      expect(arabicMsg.contains('⚡ Low Google Visibility / No Search Ads'), true);
      expect(arabicMsg.contains('مساك الله بالخير'), true);
      expect(englishMsg.contains('Low Google Visibility'), true);
      expect(englishMsg.contains('growth sprints'), true);

      // Verify email body has humanized bullet points
      final emailBody = DispatchService.generateEmailBody(lead: lead);
      expect(emailBody.contains('• Bottleneck:'), true);
      expect(emailBody.contains('I hope this email finds you well'), false); // Zero robotic fluff
    });

    test('GeminiService local heuristic accurately flags wrong contacts and triggers blacklist', () async {
      const gemini = GeminiService();
      final lead = Lead(
        id: 'test_03',
        companyName: 'Test Co',
        websiteUrl: 'https://test.com',
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Narjis Commercial Corridor',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '+966500000000',
        email: 'test@test.com',
        createdAt: DateTime.now(),
      );

      final wrongContactRes = await gemini.analyzeClientReply(
        lead: lead,
        incomingReply: 'الرقم غلط يا طيب، مين انت؟',
      );

      expect(wrongContactRes.isWrongContact, true);
      expect(wrongContactRes.sentiment, 'Wrong Contact');
      expect(wrongContactRes.strategicReply, GeminiService.politeApologyMessage);

      final highIntentRes = await gemini.analyzeClientReply(
        lead: lead,
        incomingReply: 'Yes interested, can you send details or call tomorrow?',
      );

      expect(highIntentRes.isWrongContact, false);
      expect(highIntentRes.sentiment, 'High-Intent');
      expect(highIntentRes.dealTier, '\$\$\$ Enterprise');
    });

    test('AiAnalysisResult strips markdown fences correctly', () {
      const rawWithFences = '```json\n{"sentiment": "Interested", "is_wrong_contact": false, "audit_summary": "Summary", "strategic_reply": "Reply", "deal_tier": "\$\$ Mid-Market", "next_step": "Step"}\n```';
      final cleaned = GeminiService.cleanJsonString(rawWithFences);
      expect(cleaned.startsWith('{'), true);
      expect(cleaned.endsWith('}'), true);
    });

    test('Lead handles verified live website and effective action URL correctly', () {
      final liveLead = Lead(
        id: 'test_live',
        companyName: 'Apex Falcon Real Estate',
        websiteUrl: 'https://apexfalcon.ae',
        hasLiveWebsite: true,
        primaryActionUrl: 'https://apexfalcon.ae',
        country: 'United Arab Emirates (UAE)',
        corridor: 'DIFC Financial Centre (Dubai)',
        sector: 'Luxury Real Estate Agencies',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '+971509823412',
        email: 'director@apexfalcon.ae',
        createdAt: DateTime.now(),
      );

      expect(liveLead.hasLiveWebsite, true);
      expect(liveLead.websiteUrl, 'https://apexfalcon.ae');
      expect(liveLead.effectiveActionUrl, 'https://apexfalcon.ae');
    });

    test('Lead handles dead/null website with verified Google Maps fallback', () {
      final deadLead = Lead(
        id: 'test_dead',
        companyName: 'Bahrain Bay Maritime Finance',
        websiteUrl: null,
        hasLiveWebsite: false,
        primaryActionUrl: 'https://www.google.com/maps/search/?api=1&query=Bahrain%20Bay%20Maritime%20Finance%20Bahrain%20Financial%20Harbour%20Bahrain',
        country: 'Bahrain',
        corridor: 'Bahrain Financial Harbour',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '📱 Inactive Social Media Presence',
        phone: '+97339120485',
        email: 'info@bbmaritime.bh',
        createdAt: DateTime.now(),
      );

      expect(deadLead.hasLiveWebsite, false);
      expect(deadLead.websiteUrl, isNull);
      expect(deadLead.effectiveActionUrl.startsWith('https://www.google.com/maps/search/'), true);
      expect(deadLead.fallbackMapsUrl.contains('Bahrain%20Bay%20Maritime%20Finance'), true);

      // Verify JSON round-trip
      final json = deadLead.toJson();
      expect(json['has_live_website'], false);
      expect(json['website_url'], isNull);
      expect(json['primary_action_url'], deadLead.primaryActionUrl);

      final fromJson = Lead.fromJson(json);
      expect(fromJson.hasLiveWebsite, false);
      expect(fromJson.websiteUrl, isNull);
      expect(fromJson.effectiveActionUrl, deadLead.primaryActionUrl);
    });

    test('Kuwait Cloud Commerce email pitch generates RFC-compliant mailto URI with zero plus signs', () {
      final kuwaitLead = Lead(
        id: 'mena_lead_13',
        companyName: 'Kuwait Cloud Commerce',
        websiteUrl: null,
        hasLiveWebsite: false,
        primaryActionUrl: 'https://www.google.com/maps/search/?api=1&query=Kuwait%20Cloud%20Commerce%20Sharq%20Financial%20District%20%28Kuwait%20City%29%20Kuwait',
        country: 'Kuwait',
        corridor: 'Sharq Financial District (Kuwait City)',
        sector: 'High-Growth E-Commerce Brands',
        marketingGap: '🛠️ Outdated Website / No Mobile Funnel',
        marketingGapDetails: 'High mobile bounce rate; slow responsive load times and broken booking funnel.',
        phone: '+96599812450',
        email: 'sales@kuwaitcloud.kw',
        contactName: 'Meshari Al-Mutawa',
        contactRole: 'VP Marketing',
        agreesToRemoteWork: true,
        createdAt: DateTime.now(),
      );

      final subject = DispatchService.generateEmailSubject(lead: kuwaitLead);
      final body = DispatchService.generateEmailBody(lead: kuwaitLead);

      final encSubject = DispatchService.encodeParam(subject);
      final encBody = DispatchService.encodeParam(body);

      expect(encSubject.contains('+'), false);
      expect(encBody.contains('+'), false);
      expect(encSubject.contains('%20'), true);
      expect(encBody.contains('%20'), true);

      final mailtoUri = Uri.parse('mailto:${kuwaitLead.email}?subject=$encSubject&body=$encBody');
      expect(mailtoUri.scheme, 'mailto');
      expect(mailtoUri.path, 'sales@kuwaitcloud.kw');
      expect(mailtoUri.toString().contains('+'), false);
      expect(kuwaitLead.hasLiveWebsite, false);
      expect(kuwaitLead.effectiveActionUrl.contains('maps/search'), true);
    });

    test('Lead model serializes and deserializes place_id, address, and google_maps_url correctly', () {
      const placeId = 'ChIJQ6AZBoXjLj4R2ZqOmz2WPMg';
      const mapsUrl = 'https://maps.google.com/?q=place_id:$placeId';
      const address = 'العليا، الرياض 13321';

      final genuineLead = Lead(
        id: 'riyadh_lead_01',
        companyName: 'برج المغيب المكتبي',
        placeId: placeId,
        address: address,
        googleMapsUrl: mapsUrl,
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Olaya Commercial District',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '⚡ Low Google Visibility / No Search Ads',
        phone: '+966531000216',
        email: 'info@almugheb.sa',
        createdAt: DateTime.now(),
      );

      final json = genuineLead.toJson();
      expect(json['place_id'], placeId);
      expect(json['address'], address);
      expect(json['google_maps_url'], mapsUrl);

      final reconstituted = Lead.fromJson(json);
      expect(reconstituted.placeId, placeId);
      expect(reconstituted.address, address);
      expect(reconstituted.googleMapsUrl, mapsUrl);
      expect(reconstituted.effectiveActionUrl, mapsUrl);
    });

    test('StorageService SHA-256 composite hash matches Python deduplication key', () {
      const phone = '0531000216';
      const placeId = 'ChIJQ6AZBoXjLj4R2ZqOmz2WPMg';

      final normalizedPhone = StorageService.normalizePhone(phone);
      expect(normalizedPhone, '+966531000216');

      final hash = StorageService.computeLeadHash(phone, placeId);
      // Validated against Python hashlib.sha256("+966531000216_ChIJQ6AZBoXjLj4R2ZqOmz2WPMg")
      expect(hash, '9eb08f6fefbe74e87dfa9fb72bd849460099d9442acdc62c3ba3658b89466909');
    });

    test('Lead equality and isSameBusiness correctly detect identical entities across phone, placeId, and name', () {
      final now = DateTime.now();
      final leadA = Lead(
        id: 'lead_001',
        companyName: 'Olaya Towers',
        placeId: 'ChIJK2fMfiwDLz4RFWnQIXYtzlw',
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Olaya Commercial District',
        sector: 'Management & Strategy Consulting',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '+966556550847',
        email: 'info@olayatowers.com',
        createdAt: now,
      );

      final leadB = Lead(
        id: 'lead_diff_id',
        companyName: 'Olaya Towers',
        placeId: 'ChIJK2fMfiwDLz4RFWnQIXYtzlw',
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Olaya Commercial District',
        sector: 'Management & Strategy Consulting',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '0556550847', // Local format
        email: 'info@olayatowers.com',
        createdAt: now,
      );

      expect(leadA == leadB, true);
      expect(leadA.isSameBusiness(leadB), true);
      expect({leadA, leadB}.length, 1); // Set deduplication works
    });
  });
}


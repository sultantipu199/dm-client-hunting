import 'package:flutter_test/flutter_test.dart';
import 'package:dm_client_hunting/models/lead.dart';
import 'package:dm_client_hunting/services/dispatch_service.dart';
import 'package:dm_client_hunting/services/gemini_service.dart';

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

    test('DispatchService sanitizes phone numbers for WhatsApp API', () {
      expect(DispatchService.sanitizePhoneNumber('+966 50 123 4567'), '966501234567');
      expect(DispatchService.sanitizePhoneNumber('+971-50-987-6543'), '971509876543');
      expect(DispatchService.sanitizePhoneNumber('00966501234567'), '00966501234567');
    });

    test('WhatsApp copy generation includes marketing gap and remote model', () {
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
      expect(englishMsg.contains('Cross-Border'), false); // Contains remote
      expect(englishMsg.contains('Low Google Visibility'), true);
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
  });
}

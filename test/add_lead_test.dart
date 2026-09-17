import 'package:flutter_test/flutter_test.dart';
import 'package:dm_client_hunting/models/lead.dart';

void main() {
  group('Manual Lead Entry Tests', () {
    test('Manual lead with custom corridor and fallback maps query instantiates properly', () {
      final now = DateTime.now();
      final lead = Lead(
        id: 'manual_lead_test_01',
        companyName: 'Riyadh Sky Tower Estates',
        websiteUrl: null,
        hasLiveWebsite: false,
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Malqa Prestige District',
        sector: 'Luxury Real Estate Agencies',
        marketingGap: '⚡ Low Google Visibility / No Search Ads',
        marketingGapDetails: 'Zero presence on commercial search queries in Riyadh.',
        phone: '+966509876543',
        email: 'info@riyadhsky.sa',
        contactName: 'Eng. Fahad Al-Mansoor',
        contactRole: 'Managing Director',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now,
        notes: 'Manually listed prospect ready for acquisition sprint.',
      );

      expect(lead.id, 'manual_lead_test_01');
      expect(lead.companyName, 'Riyadh Sky Tower Estates');
      expect(lead.hasLiveWebsite, false);
      expect(lead.effectiveActionUrl.contains('google.com/maps/search'), true);
      expect(lead.effectiveActionUrl.contains('Riyadh%20Sky%20Tower%20Estates'), true);
      expect(lead.phone, '+966509876543');
    });

    test('Manual lead with live corporate site sets effective action URL to website', () {
      final lead = Lead(
        id: 'manual_lead_test_02',
        companyName: 'DIFC Aura Ventures',
        websiteUrl: 'https://auraventures.ae',
        hasLiveWebsite: true,
        country: 'United Arab Emirates (UAE)',
        corridor: 'DIFC Financial Centre (Dubai)',
        sector: 'B2B Tech & SaaS Solutions',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        phone: '+971501239841',
        email: 'partner@auraventures.ae',
        createdAt: DateTime.now(),
      );

      expect(lead.effectiveActionUrl, 'https://auraventures.ae');
      expect(lead.hasLiveWebsite, true);
    });

    test('Lead model serializes and preserves manual listing notes', () {
      final lead = Lead(
        id: 'manual_lead_test_03',
        companyName: 'Lusail Apex Clinic',
        country: 'Qatar',
        corridor: 'Lusail Marina Financial District',
        sector: 'Private Healthcare & Aesthetic Clinics',
        marketingGap: '💬 No Automated WhatsApp Lead Funnel',
        phone: '+97455123456',
        email: 'consult@lusailclinic.qa',
        createdAt: DateTime.now(),
        notes: 'High-intent clinic requesting remote growth roadmap.',
      );

      final json = lead.toJson();
      final reconstituted = Lead.fromJson(json);

      expect(reconstituted.id, 'manual_lead_test_03');
      expect(reconstituted.notes, 'High-intent clinic requesting remote growth roadmap.');
      expect(reconstituted.country, 'Qatar');
      expect(reconstituted.marketingGap, '💬 No Automated WhatsApp Lead Funnel');
    });
  });
}

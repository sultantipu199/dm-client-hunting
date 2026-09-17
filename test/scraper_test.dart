import 'package:flutter_test/flutter_test.dart';
import 'package:dm_client_hunting/services/lead_scraper_service.dart';
import 'package:dm_client_hunting/models/lead.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeadScraperService Unit Tests', () {
    test('MENA corridors configuration covers target GCC hubs', () {
      expect(LeadScraperService.corridors.containsKey('Saudi Arabia (KSA)'), true);
      expect(LeadScraperService.corridors.containsKey('United Arab Emirates (UAE)'), true);
      expect(LeadScraperService.corridors.containsKey('Qatar'), true);
      expect(LeadScraperService.corridors.containsKey('Kuwait'), true);

      final ksaCorridors = LeadScraperService.corridors['Saudi Arabia (KSA)']!;
      expect(ksaCorridors.contains('KAFD Phase 1 & 2'), true);
      expect(ksaCorridors.contains('Al Narjis Commercial Corridor'), true);
    });

    test('Marketing gaps have details and actionable problem descriptions', () {
      for (final gap in LeadScraperService.marketingGaps) {
        expect(gap.containsKey('gap'), true);
        expect(gap.containsKey('details'), true);
        expect(gap['gap']!.isNotEmpty, true);
        expect(gap['details']!.isNotEmpty, true);
      }
    });

    test('Phone prefixes match respective MENA country formats', () {
      expect(LeadScraperService.phonePrefixes['Saudi Arabia (KSA)'], '+9665');
      expect(LeadScraperService.phonePrefixes['United Arab Emirates (UAE)'], '+9715');
      expect(LeadScraperService.phonePrefixes['Qatar'], '+974');
      expect(LeadScraperService.phonePrefixes['Kuwait'], '+965');
      expect(LeadScraperService.phonePrefixes['Egypt'], '+201');
    });

    test('Manual scrape generates requested number of valid leads', () async {
      final report = await LeadScraperService.runManualScrape(
        targetCountry: 'Saudi Arabia (KSA)',
        targetSector: 'All High-Ticket Sectors',
        targetCount: 5,
        mode: 'Deep Corridor Crawler',
      );

      expect(report.newLeads.length, 5);
      expect(report.sourceMode, 'Deep Corridor Crawler');

      for (final Lead lead in report.newLeads) {
        expect(lead.country, 'Saudi Arabia (KSA)');
        expect(lead.phone.startsWith('+9665'), true);
        expect(lead.email.contains('@'), true);
        expect(lead.status, 'new');
        expect(lead.agreesToRemoteWork, true);
        expect(lead.effectiveActionUrl.isNotEmpty, true);
      }
    });

    test('UAE Deep Crawler generates valid Dubai/Abu Dhabi leads', () async {
      final report = await LeadScraperService.runManualScrape(
        targetCountry: 'United Arab Emirates (UAE)',
        targetSector: 'Private Healthcare & Aesthetic Clinics',
        targetCount: 3,
        mode: 'Deep Corridor Crawler',
      );

      expect(report.newLeads.length, 3);
      for (final Lead lead in report.newLeads) {
        expect(lead.country, 'United Arab Emirates (UAE)');
        expect(lead.phone.startsWith('+9715'), true);
        expect(lead.marketingGap.isNotEmpty, true);
      }
    });
  });
}

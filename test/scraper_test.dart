import 'package:flutter_test/flutter_test.dart';
import 'package:dm_client_hunting/services/lead_scraper_service.dart';
import 'package:dm_client_hunting/models/lead.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeadScraperService Unit Tests', () {
    test('MENA corridors configuration covers required Riyadh business corridors', () {
      expect(LeadScraperService.corridors.containsKey('Saudi Arabia (KSA)'), true);
      final ksaCorridors = LeadScraperService.corridors['Saudi Arabia (KSA)']!;
      expect(ksaCorridors.contains('KAFD Phase 1 & 2'), true);
      expect(ksaCorridors.contains('Al Narjis Commercial Corridor'), true);
      expect(ksaCorridors.contains('Roshn Front Business Zone'), true);
      expect(ksaCorridors.contains('King Salman Road Business Strip'), true);
    });

    test('Marketing gaps have details and actionable problem descriptions', () {
      for (final gap in LeadScraperService.marketingGaps) {
        expect(gap.containsKey('gap'), true);
        expect(gap.containsKey('details'), true);
        expect(gap['gap']!.isNotEmpty, true);
        expect(gap['details']!.isNotEmpty, true);
      }
    });

    test('Saudi Mobile validation strictly validates +9665xxxxxxxx and rejects landlines/unified lines', () {
      // Valid Saudi Mobile Formats
      expect(LeadScraperService.isValidSaudiMobile('+966581297003'), true);
      expect(LeadScraperService.isValidSaudiMobile('0556550847'), true);
      expect(LeadScraperService.isValidSaudiMobile('508613874'), true);
      expect(LeadScraperService.isValidSaudiMobile('00966560809779'), true);
      expect(LeadScraperService.isValidSaudiMobile('+966 53 100 0216'), true);

      // Discard Landlines (011 / Riyadh landline)
      expect(LeadScraperService.isValidSaudiMobile('0112738000'), false);
      expect(LeadScraperService.isValidSaudiMobile('+966112738000'), false);

      // Discard Unified lines (9200) and Toll-Free (800)
      expect(LeadScraperService.isValidSaudiMobile('920012372'), false);
      expect(LeadScraperService.isValidSaudiMobile('+966920012372'), false);
      expect(LeadScraperService.isValidSaudiMobile('8001234567'), false);

      // Discard Malformed / Foreign numbers
      expect(LeadScraperService.isValidSaudiMobile('+971501234567'), false);
      expect(LeadScraperService.isValidSaudiMobile('051234'), false);
      expect(LeadScraperService.isValidSaudiMobile('051234567890'), false);
      expect(LeadScraperService.isValidSaudiMobile(''), false);
    });

    test('Zero Data over Fake Data guardrail: Never synthesizes fake leads on non-matching query', () async {
      final report = await LeadScraperService.runManualScrape(
        targetCountry: 'NonExistentHub',
        targetSector: 'NonExistentSector',
        targetCount: 5,
        mode: 'Deep Corridor Crawler',
      );

      // Strictly 0 leads generated, no fallback strings, no Faker names
      expect(report.newLeads.length, 0);
      expect(report.sourceMode, 'Deep Corridor Crawler');
    });
  });
}

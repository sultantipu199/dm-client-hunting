import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lead.dart';

/// Manages Hive CE persistence for leads, blacklisted contacts, and settings.
class StorageService {
  static const String leadsBoxName = 'leads_box';
  static const String blacklistContactsBoxName = 'blacklist_contacts';
  static const String settingsBoxName = 'settings_box';

  static Box<Lead>? _leadsBox;
  static Box<String>? _blacklistBox;
  static Box<dynamic>? _settingsBox;

  /// Initializes Hive, registers TypeAdapters, and opens primary boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register strongly-typed LeadAdapter if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LeadAdapter());
    }

    _leadsBox = await Hive.openBox<Lead>(leadsBoxName);
    _blacklistBox = await Hive.openBox<String>(blacklistContactsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);

    // Initial seed if leads box is empty
    if (_leadsBox!.isEmpty) {
      await _seedInitialLeads();
    }
  }

  static Box<Lead> get leadsBox {
    if (_leadsBox == null || !_leadsBox!.isOpen) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _leadsBox!;
  }

  static Box<String> get blacklistBox {
    if (_blacklistBox == null || !_blacklistBox!.isOpen) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _blacklistBox!;
  }

  static Box<dynamic> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _settingsBox!;
  }

  /// Seeds curated MENA high-ticket leads from assets/data/leads_feed.json
  static Future<void> _seedInitialLeads() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/leads_feed.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      for (final item in list) {
        final lead = Lead.fromJson(item as Map<String, dynamic>);
        // Avoid inserting if already in blacklist
        if (!isPhoneBlacklisted(lead.phone)) {
          await _leadsBox!.put(lead.id, lead);
        }
      }
    } catch (_) {
      // Fallback in-memory seed if asset load has delay
      await _seedFallbackLeads();
    }
  }

  static Future<void> _seedFallbackLeads() async {
    final now = DateTime.now();
    final sampleLeads = [
      Lead(
        id: 'mena_01',
        companyName: 'Al Narjis Elite Properties',
        websiteUrl: 'https://alnarjisproperties.com',
        country: 'Saudi Arabia (KSA)',
        corridor: 'Al Narjis Commercial Corridor',
        sector: 'Luxury Real Estate Agencies',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        marketingGapDetails: 'Zero ad retargeting; traffic bounces without tracking.',
        phone: '+966501239841',
        email: 'partnerships@alnarjisproperties.com',
        contactName: 'Eng. Fahad Al-Mansoor',
        contactRole: 'Managing Director',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      Lead(
        id: 'mena_02',
        companyName: 'KAFD Apex Capital Partners',
        websiteUrl: 'https://apexcapital.sa',
        country: 'Saudi Arabia (KSA)',
        corridor: 'KAFD Phase 1 & 2',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '⚡ Low Google Visibility / No Search Ads',
        marketingGapDetails: 'Zero presence on commercial search queries in Riyadh.',
        phone: '+966554109823',
        email: 'info@apexcapital.sa',
        contactName: 'Sultan Al-Hokair',
        contactRole: 'Managing Partner',
        agreesToRemoteWork: true,
        remoteTier: 'GCC Remote Sprints',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Lead(
        id: 'mena_03',
        companyName: 'DIFC Aura Aesthetic Clinic',
        websiteUrl: 'https://auraclinicdubai.com',
        country: 'United Arab Emirates (UAE)',
        corridor: 'DIFC Financial Centre (Dubai)',
        sector: 'Private Healthcare & Aesthetic Clinics',
        marketingGap: '🛠️ Outdated Website / No Mobile Funnel',
        marketingGapDetails: 'Mobile page takes 6.2s; booking funnel broken on iOS.',
        phone: '+971508923411',
        email: 'director@auraclinicdubai.com',
        contactName: 'Dr. Soraya Al-Hashemi',
        contactRole: 'Chief Medical Officer',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      Lead(
        id: 'mena_04',
        companyName: 'Lusail Marina Yacht Club & Charter',
        websiteUrl: 'https://lusailyachts.qa',
        country: 'Qatar',
        corridor: 'Lusail Marina Financial District',
        sector: 'Luxury Real Estate Agencies',
        marketingGap: '📱 Inactive Social Media Presence',
        marketingGapDetails: 'Last post 8 months ago despite high-season tourist influx.',
        phone: '+97455823190',
        email: 'charters@lusailyachts.qa',
        contactName: 'Nasser Al-Kuwari',
        contactRole: 'General Manager',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 22)),
      ),
      Lead(
        id: 'mena_05',
        companyName: 'New Cairo FinTech Hub',
        websiteUrl: 'https://cairofintech.eg',
        country: 'Egypt',
        corridor: 'New Cairo 5th Settlement Business Hub',
        sector: 'B2B Tech & SaaS Solutions',
        marketingGap: '🔥 Missing Meta/GTM Pixel',
        marketingGapDetails: 'Running Google Ads without conversion tracking or lead GTM tags.',
        phone: '+201019842105',
        email: 'growth@cairofintech.eg',
        contactName: 'Omar Abdel-Rahman',
        contactRole: 'Co-Founder & CEO',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 26)),
      ),
      Lead(
        id: 'mena_06',
        companyName: 'Sharq Maritime Logistics Co',
        websiteUrl: 'https://sharqlogistics.kw',
        country: 'Kuwait',
        corridor: 'Sharq Financial District (Kuwait City)',
        sector: 'Newly Formed Corporate Firms',
        marketingGap: '⚡ Low Google Visibility / No Search Ads',
        marketingGapDetails: 'Missing high-intent GCC trade freight keywords.',
        phone: '+96599182374',
        email: 'inquiries@sharqlogistics.kw',
        contactName: 'Hamad Al-Sabah',
        contactRole: 'Operations Director',
        agreesToRemoteWork: true,
        remoteTier: 'MENA Cross-Border Retainer',
        status: 'new',
        createdAt: now.subtract(const Duration(hours: 31)),
      ),
    ];

    for (final lead in sampleLeads) {
      await _leadsBox!.put(lead.id, lead);
    }
  }

  /// Marks lead as contacted with timestamp directly into Hive
  static Future<void> markLeadContacted(String leadId) async {
    final lead = _leadsBox?.get(leadId);
    if (lead != null) {
      final updated = lead.copyWith(
        status: 'contacted',
        contactedAt: DateTime.now(),
      );
      await _leadsBox!.put(leadId, updated);
    }
  }

  /// Appends phone number to blacklist Hive box and flags lead
  static Future<void> blacklistContact({
    required String leadId,
    required String phone,
    String reason = 'Wrong contact reported by recipient',
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    await blacklistBox.put(cleanPhone, reason);

    final lead = _leadsBox?.get(leadId);
    if (lead != null) {
      final updated = lead.copyWith(
        status: 'blacklisted',
        notes: 'Blacklisted: $reason',
      );
      await _leadsBox!.put(leadId, updated);
    }
  }

  /// Checks whether a phone number is registered in the blacklist Hive box
  static bool isPhoneBlacklisted(String phone) {
    if (_blacklistBox == null) return false;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return _blacklistBox!.containsKey(cleanPhone);
  }

  /// Stores AI Analysis result JSON into lead record
  static Future<void> saveAiAnalysis(String leadId, String analysisJson) async {
    final lead = _leadsBox?.get(leadId);
    if (lead != null) {
      final updated = lead.copyWith(aiAnalysisJson: analysisJson);
      await _leadsBox!.put(leadId, updated);
    }
  }

  /// Updates or sets custom Gemini API key
  static Future<void> setApiKey(String key) async {
    await settingsBox.put('gemini_api_key', key);
  }

  static String? getApiKey() {
    return settingsBox.get('gemini_api_key') as String?;
  }
}

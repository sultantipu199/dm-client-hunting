import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lead.dart';

/// Manages Hive CE persistence for leads, blacklisted contacts, processed lead deduplication registry, and settings.
class StorageService {
  static const String leadsBoxName = 'leads_box';
  static const String blacklistContactsBoxName = 'blacklist_contacts';
  static const String processedLeadsBoxName = 'processed_leads';
  static const String settingsBoxName = 'settings_box';

  static Box<Lead>? _leadsBox;
  static Box<String>? _blacklistBox;
  static Box<String>? _processedLeadsBox;
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
    _processedLeadsBox = await Hive.openBox<String>(processedLeadsBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);

    // Sync permanent lead registry into Hive box 'processed_leads'
    await syncLeadRegistry();

    // Synchronize feed leads while strictly enforcing deduplication and blacklist barriers
    await syncLeadsFromFeed();
  }

  /// Normalizes Saudi / GCC mobile phone to standard +9665xxxxxxxx format
  static String normalizePhone(String rawPhone) {
    final cleanDigits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.startsWith('9665') && cleanDigits.length == 12) {
      return '+$cleanDigits';
    } else if (cleanDigits.startsWith('05') && cleanDigits.length == 10) {
      return '+966${cleanDigits.substring(1)}';
    } else if (cleanDigits.startsWith('5') && cleanDigits.length == 9) {
      return '+966$cleanDigits';
    }
    return rawPhone.startsWith('+') ? rawPhone : '+$cleanDigits';
  }

  /// Generates composite SHA-256 hash: SHA256(normalized_phone + "_" + place_id)
  static String computeLeadHash(String phone, String placeId) {
    final normalized = normalizePhone(phone);
    final key = '${normalized}_${placeId.trim()}';
    return sha256.convert(utf8.encode(key)).toString();
  }

  /// Synchronizes entries from assets/data/lead_registry.json into Hive box 'processed_leads'
  static Future<void> syncLeadRegistry() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/lead_registry.json');
      final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
      final entries = data['entries'] as Map<String, dynamic>? ?? {};

      for (final entry in entries.entries) {
        final hashKey = entry.key;
        final details = entry.value is Map<String, dynamic>
            ? jsonEncode(entry.value)
            : entry.value.toString();
        await _processedLeadsBox?.put(hashKey, details);
      }
    } catch (_) {
      // Asset not yet present or empty
    }
  }

  /// Checks if a lead has already been processed using its composite hash
  static bool isLeadProcessed(String phone, String placeId) {
    if (_processedLeadsBox == null) return false;
    final hashKey = computeLeadHash(phone, placeId);
    return _processedLeadsBox!.containsKey(hashKey);
  }

  /// Checks if a specific SHA-256 hashKey exists in processed leads
  static bool isHashProcessed(String hashKey) {
    if (_processedLeadsBox == null) return false;
    return _processedLeadsBox!.containsKey(hashKey);
  }

  /// Marks lead as processed in Hive box 'processed_leads'
  static Future<void> markLeadProcessed({
    required String phone,
    required String placeId,
    String? companyName,
    String? dateAdded,
  }) async {
    final hashKey = computeLeadHash(phone, placeId);
    final date = dateAdded ?? DateTime.now().toIso8601String().substring(0, 10);
    final record = jsonEncode({
      'hash_key': hashKey,
      'place_id': placeId,
      'phone': normalizePhone(phone),
      'company_name': companyName ?? '',
      'date_added': date,
    });
    await _processedLeadsBox?.put(hashKey, record);
  }

  /// Synchronizes leads from assets/data/leads_feed.json with local Hive storage.
  /// Strictly drops leads if duplicate or blacklisted.
  /// Preserves user interaction state (contacted status, notes, AI analysis).
  static Future<void> syncLeadsFromFeed() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/leads_feed.json');
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;

      for (final item in list) {
        final feedLead = Lead.fromJson(item as Map<String, dynamic>);

        // Pre-Ingestion Check 1: Blacklist
        if (isPhoneBlacklisted(feedLead.phone)) continue;

        // Pre-Ingestion Check 2: Deduplication by Place ID and Normalized Phone Hash
        final placeId = feedLead.placeId ?? feedLead.id;
        final hashKey = computeLeadHash(feedLead.phone, placeId);

        final existing = _leadsBox?.get(feedLead.id);
        if (existing != null) {
          // Merge metadata while strictly preserving user interaction status
          final updated = feedLead.copyWith(
            status: existing.status,
            contactedAt: existing.contactedAt,
            notes: existing.notes.isNotEmpty ? existing.notes : feedLead.notes,
            aiAnalysisJson: existing.aiAnalysisJson ?? feedLead.aiAnalysisJson,
          );
          await _leadsBox?.put(feedLead.id, updated);
          await markLeadProcessed(
            phone: feedLead.phone,
            placeId: placeId,
            companyName: feedLead.companyName,
          );
        } else {
          // Check if this business/phone combination was ever ingested before
          if (isHashProcessed(hashKey)) {
            // Already processed in permanent registry - DROP IMMEDIATELY
            continue;
          }
          // Genuine new lead ingestion
          await _leadsBox?.put(feedLead.id, feedLead);
          await markLeadProcessed(
            phone: feedLead.phone,
            placeId: placeId,
            companyName: feedLead.companyName,
          );
        }
      }
    } catch (_) {
      // Fallback silently if asset load encounters an issue
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

  static Box<String> get processedLeadsBox {
    if (_processedLeadsBox == null || !_processedLeadsBox!.isOpen) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _processedLeadsBox!;
  }

  static Box<dynamic> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _settingsBox!;
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
    final normalized = normalizePhone(phone);
    return _blacklistBox!.containsKey(cleanPhone) ||
        _blacklistBox!.containsKey(normalized) ||
        _blacklistBox!.containsKey(phone);
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

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

  // Ultra-fast in-memory indexing for zero-collision duplicate rejection
  static final Set<String> _knownPhones = <String>{};
  static final Set<String> _knownPlaceIds = <String>{};
  static final Set<String> _knownCompanyNames = <String>{};
  static final Set<String> _knownHashes = <String>{};
  static final Set<String> _knownLeadIds = <String>{};

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

    // Rebuild in-memory indexing
    _rebuildKnownIndices();

    // Synchronize feed leads while strictly enforcing deduplication and blacklist barriers
    await syncLeadsFromFeed();
  }

  /// Normalizes company name to lowercase alphanumeric for robust match
  static String normalizeCompanyName(String rawName) {
    return rawName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '').trim();
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

  static void _rebuildKnownIndices() {
    _knownPhones.clear();
    _knownPlaceIds.clear();
    _knownCompanyNames.clear();
    _knownHashes.clear();
    _knownLeadIds.clear();

    if (_leadsBox != null) {
      for (final lead in _leadsBox!.values) {
        _indexLead(lead);
      }
    }

    if (_processedLeadsBox != null) {
      for (final key in _processedLeadsBox!.keys) {
        final hashKey = key.toString();
        _knownHashes.add(hashKey);
        try {
          final raw = _processedLeadsBox!.get(hashKey);
          if (raw != null) {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            final p = map['phone']?.toString();
            final pid = map['place_id']?.toString();
            final cname = map['company_name']?.toString();
            if (p != null && p.isNotEmpty) _knownPhones.add(normalizePhone(p));
            if (pid != null && pid.isNotEmpty) _knownPlaceIds.add(pid.trim());
            if (cname != null && cname.isNotEmpty) _knownCompanyNames.add(normalizeCompanyName(cname));
          }
        } catch (_) {}
      }
    }
  }

  static void _indexLead(Lead lead) {
    _knownLeadIds.add(lead.id);
    final normP = normalizePhone(lead.phone);
    if (normP.isNotEmpty) _knownPhones.add(normP);
    if (lead.placeId != null && lead.placeId!.trim().isNotEmpty) {
      _knownPlaceIds.add(lead.placeId!.trim());
    }
    final normName = normalizeCompanyName(lead.companyName);
    if (normName.isNotEmpty) _knownCompanyNames.add(normName);
    final placeId = lead.placeId ?? lead.id;
    _knownHashes.add(computeLeadHash(lead.phone, placeId));
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
        _knownHashes.add(hashKey);

        if (entry.value is Map<String, dynamic>) {
          final m = entry.value as Map<String, dynamic>;
          final p = m['phone']?.toString();
          final pid = m['place_id']?.toString();
          final cname = m['company_name']?.toString();
          if (p != null && p.isNotEmpty) _knownPhones.add(normalizePhone(p));
          if (pid != null && pid.isNotEmpty) _knownPlaceIds.add(pid.trim());
          if (cname != null && cname.isNotEmpty) _knownCompanyNames.add(normalizeCompanyName(cname));
        }
      }
    } catch (_) {
      // Asset not yet present or empty
    }
  }

  /// Checks if a lead has already been processed using its composite hash
  static bool isLeadProcessed(String phone, String placeId) {
    final hashKey = computeLeadHash(phone, placeId);
    if (_knownHashes.contains(hashKey)) return true;
    if (_processedLeadsBox == null) return false;
    return _processedLeadsBox!.containsKey(hashKey);
  }

  /// Checks if a specific SHA-256 hashKey exists in processed leads
  static bool isHashProcessed(String hashKey) {
    if (_knownHashes.contains(hashKey)) return true;
    if (_processedLeadsBox == null) return false;
    return _processedLeadsBox!.containsKey(hashKey);
  }

  /// 5-Layer Bulletproof Deduplication Barrier:
  /// Guarantees that no lead with the same Phone, Place ID, Company Name,
  /// Composite SHA-256 Hash, or Lead ID is ever returned or stored twice.
  static bool isDuplicateLead({
    required String phone,
    String? placeId,
    String? companyName,
    String? id,
  }) {
    if (id != null && _knownLeadIds.contains(id)) return true;
    final normP = normalizePhone(phone);
    if (normP.isNotEmpty && _knownPhones.contains(normP)) return true;
    if (placeId != null && placeId.trim().isNotEmpty && _knownPlaceIds.contains(placeId.trim())) {
      return true;
    }
    if (companyName != null && companyName.trim().isNotEmpty) {
      final normName = normalizeCompanyName(companyName);
      if (normName.isNotEmpty && _knownCompanyNames.contains(normName)) return true;
    }
    final effectivePlaceId = (placeId != null && placeId.trim().isNotEmpty) ? placeId.trim() : id;
    if (effectivePlaceId != null) {
      final hash = computeLeadHash(phone, effectivePlaceId);
      if (_knownHashes.contains(hash)) return true;
      if (_processedLeadsBox?.containsKey(hash) ?? false) return true;
    }
    return false;
  }

  /// Marks lead as processed across all persistent and in-memory deduplication layers
  static Future<void> markLeadProcessed({
    required String phone,
    required String placeId,
    String? companyName,
    String? dateAdded,
    String? id,
  }) async {
    final normP = normalizePhone(phone);
    final normPid = placeId.trim();
    final normName = companyName != null ? normalizeCompanyName(companyName) : '';
    final hashKey = computeLeadHash(phone, placeId);
    final date = dateAdded ?? DateTime.now().toIso8601String().substring(0, 10);

    final record = jsonEncode({
      'hash_key': hashKey,
      'place_id': normPid,
      'phone': normP,
      'company_name': companyName ?? '',
      'date_added': date,
    });

    await _processedLeadsBox?.put(hashKey, record);

    if (id != null) _knownLeadIds.add(id);
    if (normP.isNotEmpty) _knownPhones.add(normP);
    if (normPid.isNotEmpty) _knownPlaceIds.add(normPid);
    if (normName.isNotEmpty) _knownCompanyNames.add(normName);
    _knownHashes.add(hashKey);
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
          _indexLead(updated);
        } else {
          // Check if this lead already exists under a different key in leadsBox
          final alreadyExistsInBox = _leadsBox?.values.any((l) =>
              l.id == feedLead.id ||
              l.normalizedPhone == feedLead.normalizedPhone ||
              (l.placeId != null && l.placeId == feedLead.placeId) ||
              l.normalizedCompanyName == feedLead.normalizedCompanyName) ?? false;

          if (alreadyExistsInBox) {
            continue;
          }

          // Genuine new lead ingestion
          await _leadsBox?.put(feedLead.id, feedLead);
          _indexLead(feedLead);
          await markLeadProcessed(
            phone: feedLead.phone,
            placeId: feedLead.placeId ?? feedLead.id,
            companyName: feedLead.companyName,
            id: feedLead.id,
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

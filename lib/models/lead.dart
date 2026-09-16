import 'package:hive/hive.dart';

/// Strongly-typed Lead Model with direct Hive CE serialization support.
class Lead {
  final String id;
  final String companyName;
  final String websiteUrl;
  final String country;
  final String corridor;
  final String sector;
  final String marketingGap;
  final String marketingGapDetails;
  final String phone;
  final String email;
  final String contactName;
  final String contactRole;
  final bool agreesToRemoteWork;
  final String remoteTier;
  final String status; // 'new' | 'contacted' | 'blacklisted' | 'won'
  final DateTime? contactedAt;
  final DateTime createdAt;
  final String notes;
  final String? aiAnalysisJson;

  const Lead({
    required this.id,
    required this.companyName,
    required this.websiteUrl,
    required this.country,
    required this.corridor,
    required this.sector,
    required this.marketingGap,
    this.marketingGapDetails = '',
    required this.phone,
    required this.email,
    this.contactName = '',
    this.contactRole = '',
    this.agreesToRemoteWork = true,
    this.remoteTier = 'MENA Cross-Border Retainer',
    this.status = 'new',
    this.contactedAt,
    required this.createdAt,
    this.notes = '',
    this.aiAnalysisJson,
  });

  Lead copyWith({
    String? id,
    String? companyName,
    String? websiteUrl,
    String? country,
    String? corridor,
    String? sector,
    String? marketingGap,
    String? marketingGapDetails,
    String? phone,
    String? email,
    String? contactName,
    String? contactRole,
    bool? agreesToRemoteWork,
    String? remoteTier,
    String? status,
    DateTime? contactedAt,
    DateTime? createdAt,
    String? notes,
    String? aiAnalysisJson,
  }) {
    return Lead(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      country: country ?? this.country,
      corridor: corridor ?? this.corridor,
      sector: sector ?? this.sector,
      marketingGap: marketingGap ?? this.marketingGap,
      marketingGapDetails: marketingGapDetails ?? this.marketingGapDetails,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactName: contactName ?? this.contactName,
      contactRole: contactRole ?? this.contactRole,
      agreesToRemoteWork: agreesToRemoteWork ?? this.agreesToRemoteWork,
      remoteTier: remoteTier ?? this.remoteTier,
      status: status ?? this.status,
      contactedAt: contactedAt ?? this.contactedAt,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      aiAnalysisJson: aiAnalysisJson ?? this.aiAnalysisJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'website_url': websiteUrl,
      'country': country,
      'corridor': corridor,
      'sector': sector,
      'marketing_gap': marketingGap,
      'marketing_gap_details': marketingGapDetails,
      'phone': phone,
      'email': email,
      'contact_name': contactName,
      'contact_role': contactRole,
      'agrees_to_remote_work': agreesToRemoteWork,
      'remote_tier': remoteTier,
      'status': status,
      'contacted_at': contactedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'ai_analysis_json': aiAnalysisJson,
    };
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      companyName: json['company_name'] as String? ?? 'Enterprise Client',
      websiteUrl: json['website_url'] as String? ?? 'https://example.com',
      country: json['country'] as String? ?? 'Saudi Arabia (KSA)',
      corridor: json['corridor'] as String? ?? 'KAFD Phase 1 & 2',
      sector: json['sector'] as String? ?? 'Newly Formed Corporate Firms',
      marketingGap: json['marketing_gap'] as String? ?? '🔥 Missing Meta/GTM Pixel',
      marketingGapDetails: json['marketing_gap_details'] as String? ?? '',
      phone: json['phone'] as String? ?? '+966500000000',
      email: json['email'] as String? ?? 'info@example.com',
      contactName: json['contact_name'] as String? ?? '',
      contactRole: json['contact_role'] as String? ?? 'Executive Partner',
      agreesToRemoteWork: json['agrees_to_remote_work'] as bool? ?? true,
      remoteTier: json['remote_tier'] as String? ?? 'MENA Cross-Border Retainer',
      status: json['status'] as String? ?? 'new',
      contactedAt: json['contacted_at'] != null
          ? DateTime.tryParse(json['contacted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      aiAnalysisJson: json['ai_analysis_json'] as String?,
    );
  }
}

/// Hive Strongly-Typed TypeAdapter for Lead
class LeadAdapter extends TypeAdapter<Lead> {
  @override
  final int typeId = 0;

  @override
  Lead read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lead(
      id: fields[0] as String,
      companyName: fields[1] as String,
      websiteUrl: fields[2] as String,
      country: fields[3] as String,
      corridor: fields[4] as String,
      sector: fields[5] as String,
      marketingGap: fields[6] as String,
      marketingGapDetails: fields[7] as String? ?? '',
      phone: fields[8] as String,
      email: fields[9] as String,
      contactName: fields[10] as String? ?? '',
      contactRole: fields[11] as String? ?? '',
      agreesToRemoteWork: fields[12] as bool? ?? true,
      remoteTier: fields[13] as String? ?? 'MENA Cross-Border Retainer',
      status: fields[14] as String? ?? 'new',
      contactedAt: fields[15] != null ? DateTime.tryParse(fields[15] as String) : null,
      createdAt: fields[16] != null ? DateTime.parse(fields[16] as String) : DateTime.now(),
      notes: fields[17] as String? ?? '',
      aiAnalysisJson: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Lead obj) {
    writer.writeByte(19);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.companyName);
    writer.writeByte(2);
    writer.write(obj.websiteUrl);
    writer.writeByte(3);
    writer.write(obj.country);
    writer.writeByte(4);
    writer.write(obj.corridor);
    writer.writeByte(5);
    writer.write(obj.sector);
    writer.writeByte(6);
    writer.write(obj.marketingGap);
    writer.writeByte(7);
    writer.write(obj.marketingGapDetails);
    writer.writeByte(8);
    writer.write(obj.phone);
    writer.writeByte(9);
    writer.write(obj.email);
    writer.writeByte(10);
    writer.write(obj.contactName);
    writer.writeByte(11);
    writer.write(obj.contactRole);
    writer.writeByte(12);
    writer.write(obj.agreesToRemoteWork);
    writer.writeByte(13);
    writer.write(obj.remoteTier);
    writer.writeByte(14);
    writer.write(obj.status);
    writer.writeByte(15);
    writer.write(obj.contactedAt?.toIso8601String());
    writer.writeByte(16);
    writer.write(obj.createdAt.toIso8601String());
    writer.writeByte(17);
    writer.write(obj.notes);
    writer.writeByte(18);
    writer.write(obj.aiAnalysisJson);
  }
}

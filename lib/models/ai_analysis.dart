import 'dart:convert';

/// Data structure for Gemini 1.5 Flash Strategic Growth Analyst response.
class AiAnalysisResult {
  final String sentiment; // "Interested | High-Intent | Budget Objection | Competitor Bound | Wrong Contact"
  final bool isWrongContact;
  final String auditSummary;
  final String strategicReply;
  final String dealTier; // "$$$ Enterprise | $$ Mid-Market | $ Starter Retainer"
  final String nextStep;
  final String rawReplySnippet;

  const AiAnalysisResult({
    required this.sentiment,
    required this.isWrongContact,
    required this.auditSummary,
    required this.strategicReply,
    required this.dealTier,
    required this.nextStep,
    this.rawReplySnippet = '',
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json, {String rawSnippet = ''}) {
    return AiAnalysisResult(
      sentiment: json['sentiment']?.toString() ?? 'Interested',
      isWrongContact: json['is_wrong_contact'] == true,
      auditSummary: json['audit_summary']?.toString() ?? 'Lead engagement opportunity detected.',
      strategicReply: json['strategic_reply']?.toString() ??
          'Thanks for connecting! Would you be open to a 10-minute growth roadmap session this week to review your digital performance bottlenecks?',
      dealTier: json['deal_tier']?.toString() ?? '\$\$ Mid-Market',
      nextStep: json['next_step']?.toString() ?? 'Schedule 10-minute Zoom/Google Meet discovery call.',
      rawReplySnippet: rawSnippet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentiment': sentiment,
      'is_wrong_contact': isWrongContact,
      'audit_summary': auditSummary,
      'strategic_reply': strategicReply,
      'deal_tier': dealTier,
      'next_step': nextStep,
      'raw_reply_snippet': rawReplySnippet,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AiAnalysisResult.fromJsonString(String str) {
    try {
      final Map<String, dynamic> map = jsonDecode(str) as Map<String, dynamic>;
      return AiAnalysisResult.fromJson(map);
    } catch (_) {
      return const AiAnalysisResult(
        sentiment: 'Interested',
        isWrongContact: false,
        auditSummary: 'Parsed analysis',
        strategicReply: 'Shall we schedule a brief 10-minute call to review your acquisition targets?',
        dealTier: '\$\$ Mid-Market',
        nextStep: 'Confirm discovery call timing',
      );
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class TennisbearImportPreviewApiException implements Exception {
  TennisbearImportPreviewApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  @override
  String toString() => message;
}

class TennisbearImportPreviewApiClient {
  TennisbearImportPreviewApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<TennisbearImportPreviewResponse> preview({
    required String sourceUrl,
  }) async {
    final uri = _buildUri('/api/v1/imports/tennisbear-event:preview');

    final response = await _httpClient.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'source_url': sourceUrl,
      }),
    );

    final decoded = _decodeJsonObject(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TennisbearImportPreviewApiException(
        statusCode: response.statusCode,
        message: decoded['message']?.toString() ??
            'Failed to load event information.',
        body: decoded,
      );
    }

    return TennisbearImportPreviewResponse.fromJson(decoded);
  }

  Uri _buildUri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(normalizedBaseUrl).resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw TennisbearImportPreviewApiException(
      statusCode: response.statusCode,
      message: 'response is not a JSON object',
    );
  }
}

class TennisbearImportPreviewResponse {
  TennisbearImportPreviewResponse({
    required this.sourceType,
    required this.sourceUrl,
    required this.sourceEventId,
    required this.participantCandidates,
    this.eventCandidate,
    this.participantSummary,
    this.warnings = const [],
  });

  factory TennisbearImportPreviewResponse.fromJson(Map<String, dynamic> json) {
    return TennisbearImportPreviewResponse(
      sourceType: json['source_type']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      sourceEventId: json['source_event_id']?.toString() ?? '',
      eventCandidate: json['event_candidate'] is Map<String, dynamic>
          ? TennisbearEventCandidate.fromJson(
              json['event_candidate'] as Map<String, dynamic>,
            )
          : null,
      participantSummary: json['participant_summary'] is Map<String, dynamic>
          ? TennisbearParticipantSummary.fromJson(
              json['participant_summary'] as Map<String, dynamic>,
            )
          : null,
      participantCandidates: _asObjectList(json['participant_candidates'])
          .map(TennisbearParticipantCandidate.fromJson)
          .toList(growable: false),
      warnings: _asObjectList(json['warnings'])
          .map(TennisbearImportPreviewWarning.fromJson)
          .toList(growable: false),
    );
  }

  final String sourceType;
  final String sourceUrl;
  final String sourceEventId;
  final TennisbearEventCandidate? eventCandidate;
  final TennisbearParticipantSummary? participantSummary;
  final List<TennisbearParticipantCandidate> participantCandidates;
  final List<TennisbearImportPreviewWarning> warnings;
}

class TennisbearEventCandidate {
  TennisbearEventCandidate({
    required this.title,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.courtCount,
    required this.notes,
  });

  factory TennisbearEventCandidate.fromJson(Map<String, dynamic> json) {
    return TennisbearEventCandidate(
      title: json['title']?.toString() ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      courtCount: int.tryParse(json['court_count']?.toString() ?? '') ?? 0,
      notes: json['notes']?.toString() ?? '',
    );
  }

  final String title;
  final String eventDate;
  final String startTime;
  final String endTime;
  final String location;
  final int courtCount;
  final String notes;
}

class TennisbearParticipantSummary {
  TennisbearParticipantSummary({
    required this.currentCount,
    required this.capacity,
    required this.isPrivate,
  });

  factory TennisbearParticipantSummary.fromJson(Map<String, dynamic> json) {
    return TennisbearParticipantSummary(
      currentCount: int.tryParse(json['current_count']?.toString() ?? '') ?? 0,
      capacity: int.tryParse(json['capacity']?.toString() ?? '') ?? 0,
      isPrivate: json['is_private'] == true,
    );
  }

  final int currentCount;
  final int capacity;
  final bool isPrivate;
}

class TennisbearParticipantCandidate {
  TennisbearParticipantCandidate({
    required this.displayName,
    required this.orderNo,
    required this.status,
    required this.userId,
    required this.profileUrl,
    required this.sourceText,
  });

  factory TennisbearParticipantCandidate.fromJson(Map<String, dynamic> json) {
    return TennisbearParticipantCandidate(
      displayName: json['display_name']?.toString() ?? '',
      orderNo: int.tryParse(json['order_no']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      profileUrl: json['profile_url']?.toString() ?? '',
      sourceText: json['source_text']?.toString() ?? '',
    );
  }

  final String displayName;
  final int orderNo;
  final String status;
  final String userId;
  final String profileUrl;
  final String sourceText;
}

class TennisbearImportPreviewWarning {
  TennisbearImportPreviewWarning({
    required this.code,
    required this.message,
    required this.target,
  });

  factory TennisbearImportPreviewWarning.fromJson(Map<String, dynamic> json) {
    return TennisbearImportPreviewWarning(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
    );
  }

  final String code;
  final String message;
  final String target;
}

List<Map<String, dynamic>> _asObjectList(Object? value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

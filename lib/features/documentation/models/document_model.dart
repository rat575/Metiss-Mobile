class DocumentRecord {
  final String uuid;
  final String documentType;
  final String serviceName;
  final String status;
  final String term;
  final DateTime? executedDate;
  final DateTime? effectiveDate;
  final String? documentSignedUrl;
  final String? organizationId;

  DocumentRecord({
    required this.uuid,
    required this.documentType,
    required this.serviceName,
    required this.status,
    required this.term,
    this.executedDate,
    this.effectiveDate,
    this.documentSignedUrl,
    this.organizationId,
  });

  factory DocumentRecord.fromJson(Map<String, dynamic> json) {
    return DocumentRecord(
      uuid: json['uuid'] ?? '',
      documentType: json['documentType'] ?? '',
      serviceName: json['serviceName'] ?? '',
      status: json['status'] ?? '',
      term: json['term'] ?? '',
      executedDate: json['executedDate'] != null ? DateTime.tryParse(json['executedDate']) : null,
      effectiveDate: json['effectiveDate'] != null ? DateTime.tryParse(json['effectiveDate']) : null,
      documentSignedUrl: json['documentSignedUrl'],
      organizationId: json['organizationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'documentType': documentType,
      'serviceName': serviceName,
      'status': status,
      'term': term,
      'executedDate': executedDate?.toIso8601String(),
      'effectiveDate': effectiveDate?.toIso8601String(),
      'documentSignedUrl': documentSignedUrl,
      'organizationId': organizationId,
    };
  }
}

class DocumentListResponse {
  final List<DocumentRecord> documents;
  final int page;
  final int total;
  final int perPage;

  DocumentListResponse({
    required this.documents,
    required this.page,
    required this.total,
    required this.perPage,
  });

  factory DocumentListResponse.fromJson(Map<String, dynamic> json) {
    final docsList = json['documents'] as List? ?? [];
    return DocumentListResponse(
      documents: docsList.map((doc) => DocumentRecord.fromJson(doc as Map<String, dynamic>)).toList(),
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      perPage: json['perPage'] ?? 10,
    );
  }
}

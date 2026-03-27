class Field {
  final String fieldId;
  final String fieldName;
  final String? url;
  final String? description;
  final String? thumbnailUrl;

  Field({
    required this.fieldId,
    required this.fieldName,
    this.url,
    this.description,
    this.thumbnailUrl,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      fieldId: json['fieldId'] as String,
      fieldName: json['fieldName'] as String,
      url: json['url'] as String?,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'fieldName': fieldName,
      'url': url,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

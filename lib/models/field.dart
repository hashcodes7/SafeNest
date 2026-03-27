class Field {
  final String fieldId;
  final String fieldName;
  final String? url;
  final String? data;

  Field({
    required this.fieldId,
    required this.fieldName,
    this.url,
    this.data,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      fieldId: json['fieldId'] as String,
      fieldName: json['fieldName'] as String,
      url: json['url'] as String?,
      data: json['data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'fieldName': fieldName,
      'url': url,
      'data': data,
    };
  }
}

import 'field.dart';

class Collection {
  final String collectionId;
  final String collectionName;
  final List<Field> fields;

  Collection({
    required this.collectionId,
    required this.collectionName,
    required this.fields,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      collectionId: json['collectionId'] as String,
      collectionName: json['collectionName'] as String,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => Field.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collectionId': collectionId,
      'collectionName': collectionName,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

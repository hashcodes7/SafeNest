import 'field.dart';

class Collection {
  final String collectionId;
  final String collectionName;
  final int? iconCodePoint;
  final List<Field> fields;

  Collection({
    required this.collectionId,
    required this.collectionName,
    this.iconCodePoint,
    required this.fields,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      collectionId: json['collectionId'] as String,
      collectionName: json['collectionName'] as String,
      iconCodePoint: json['iconCodePoint'] as int?,
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
      'iconCodePoint': iconCodePoint,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

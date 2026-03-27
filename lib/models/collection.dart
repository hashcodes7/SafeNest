import 'field.dart';

class Collection {
  final String collectionId;
  String collectionName;
  int? iconCodePoint;
  bool isLocked;
  final List<Field> fields;

  Collection({
    required this.collectionId,
    required this.collectionName,
    this.iconCodePoint,
    this.isLocked = false,
    required this.fields,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      collectionId: json['collectionId'] as String,
      collectionName: json['collectionName'] as String,
      iconCodePoint: json['iconCodePoint'] as int?,
      isLocked: json['isLocked'] as bool? ?? false,
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
      'isLocked': isLocked,
      'fields': fields.map((e) => e.toJson()).toList(),
    };
  }
}

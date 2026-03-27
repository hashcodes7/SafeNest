import 'collection.dart';

class User {
  final String userId;
  final String userName;
  final List<Collection> collections;

  User({
    required this.userId,
    required this.userName,
    required this.collections,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      collections: (json['collections'] as List<dynamic>?)
              ?.map((e) => Collection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'collections': collections.map((e) => e.toJson()).toList(),
    };
  }
}

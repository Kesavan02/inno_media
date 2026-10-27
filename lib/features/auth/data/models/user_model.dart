import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String passwordHash;
  final String salt;

  const UserModel({
    required super.id,
    required super.fullName,
    required super.mobile,
    required super.email,
    required super.avatarUrl,
    super.bio,
    required super.createdAt,
    required this.passwordHash,
    required this.salt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      bio: json['bio'] as String? ?? 'Flutter & Clean Architecture Developer',
      createdAt: DateTime.parse(json['createdAt'] as String),
      passwordHash: json['passwordHash'] as String,
      salt: json['salt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'passwordHash': passwordHash,
      'salt': salt,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      fullName: fullName,
      mobile: mobile,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      createdAt: createdAt,
    );
  }
}

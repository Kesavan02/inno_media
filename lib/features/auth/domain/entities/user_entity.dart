import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String avatarUrl;
  final String bio;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.avatarUrl,
    this.bio = 'Flutter & Clean Architecture Enthusiast',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, fullName, mobile, email, avatarUrl, bio, createdAt];
}

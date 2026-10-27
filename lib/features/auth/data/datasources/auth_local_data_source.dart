import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/password_hasher.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> register({
    required String fullName,
    required String mobile,
    required String rawPassword,
    required String email,
  });

  Future<UserModel> login({
    required String mobile,
    required String rawPassword,
  });

  Future<UserModel?> getCurrentUser();

  Future<void> logout();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> register({
    required String fullName,
    required String mobile,
    required String rawPassword,
    required String email,
  }) async {
    final usersMap = _getUsersMap();

    if (usersMap.containsKey(mobile)) {
      throw const AuthException('An account with this mobile number already exists.');
    }

    // Generate unique salt and compute SHA-256 hash (never store plain password)
    final userSalt = DateTime.now().microsecondsSinceEpoch.toString();
    final passwordHash = PasswordHasher.hashPassword(rawPassword, userSalt: userSalt);

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      mobile: mobile,
      email: email,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
      bio: 'InnoMedia Creator & Tech Innovator',
      createdAt: DateTime.now(),
      passwordHash: passwordHash,
      salt: userSalt,
    );

    usersMap[mobile] = newUser.toJson();
    await _saveUsersMap(usersMap);
    await _saveCurrentSession(newUser);

    return newUser;
  }

  @override
  Future<UserModel> login({
    required String mobile,
    required String rawPassword,
  }) async {
    final usersMap = _getUsersMap();

    // Default seeded demo user if fresh install
    if (usersMap.isEmpty && mobile == '9876543210' && rawPassword == 'Password@123') {
      return await register(
        fullName: 'Alex Johnson',
        mobile: '9876543210',
        rawPassword: 'Password@123',
        email: 'alex.johnson@innomedia.io',
      );
    }

    if (!usersMap.containsKey(mobile)) {
      throw const AuthException('No account found with this mobile number. Please register.');
    }

    final userData = usersMap[mobile] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    final isValid = PasswordHasher.verifyPassword(
      rawPassword: rawPassword,
      storedHash: user.passwordHash,
      userSalt: user.salt,
    );

    if (!isValid) {
      throw const AuthException('Invalid password. Please check your credentials.');
    }

    await _saveCurrentSession(user);
    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final sessionString = sharedPreferences.getString(AppConstants.keyCurrentUser);
    if (sessionString == null) return null;
    try {
      final json = jsonDecode(sessionString) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove(AppConstants.keyCurrentUser);
  }

  Map<String, dynamic> _getUsersMap() {
    final rawString = sharedPreferences.getString(AppConstants.keyUserDatabase);
    if (rawString == null) return {};
    try {
      return jsonDecode(rawString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsersMap(Map<String, dynamic> map) async {
    await sharedPreferences.setString(AppConstants.keyUserDatabase, jsonEncode(map));
  }

  Future<void> _saveCurrentSession(UserModel user) async {
    await sharedPreferences.setString(AppConstants.keyCurrentUser, jsonEncode(user.toJson()));
  }
}

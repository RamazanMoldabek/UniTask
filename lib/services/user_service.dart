import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'database_helper.dart';

class _RegisteredAccount {
  final UserProfile profile;
  final String password;

  const _RegisteredAccount({
    required this.profile,
    required this.password,
  });
}

class UserService extends ChangeNotifier {
  static final UserService instance = UserService._internal();
  factory UserService() => instance;
  UserService._internal();

  static const String _backendBaseUrl = 'https://unitask-6er3.onrender.com';

  UserProfile _currentUser = const UserProfile(
    id: 1,
    fullName: 'Рамазан Т.',
    university: 'Astana IT University',
    email: 'ramazan.t@astanait.edu.kz',
  );

  final Map<String, _RegisteredAccount> _registeredUsers = {};

  UserProfile get currentUser => _currentUser;

  String get firstName {
    final trimmed = _currentUser.fullName.trim();
    if (trimmed.isEmpty) return 'Студент';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final trimmed = _currentUser.fullName.trim();
    if (trimmed.isEmpty) return 'UT';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final single = parts.first;
    return single.length >= 2
        ? single.substring(0, 2).toUpperCase()
        : single[0].toUpperCase();
  }

  Future<void> init() async {
    final saved = await DatabaseHelper.instance.getUserProfile();
    if (saved != null && saved.fullName.trim().isNotEmpty) {
      _currentUser = saved;
      notifyListeners();
    }
  }

  Future<UserProfile> register({
    required String fullName,
    required String university,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanUni = university.trim();
    final cleanEmail = email.trim();

    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch,
      fullName: cleanName,
      university: cleanUni,
      email: cleanEmail,
    );

    _registeredUsers[cleanEmail.toLowerCase()] = _RegisteredAccount(
      profile: profile,
      password: password,
    );
    _currentUser = profile;
    notifyListeners();

    await DatabaseHelper.instance.saveUserProfile(profile);

    // Sync with backend if endpoint is available
    try {
      await http
          .post(
            Uri.parse('$_backendBaseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': cleanName,
              'university': cleanUni,
              'email': cleanEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    return profile;
  }

  /// Returns `null` on success, or an error message string if credentials fail.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final key = cleanEmail.toLowerCase();

    // 1. Check locally registered users first
    final localAccount = _registeredUsers[key];
    if (localAccount != null) {
      if (localAccount.password != password) {
        return 'Құпиясөз қате';
      }
      _currentUser = localAccount.profile;
      notifyListeners();
      await DatabaseHelper.instance.saveUserProfile(_currentUser);
      return null;
    }

    // 2. Try backend /auth/login
    try {
      final response = await http
          .post(
            Uri.parse('$_backendBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userMap = (data['user'] as Map<String, dynamic>?) ?? data;
        final profile = UserProfile(
          fullName: (userMap['fullName'] ?? userMap['full_name'] ?? '').toString(),
          university: (userMap['university'] ?? 'Astana IT University').toString(),
          email: (userMap['email'] ?? cleanEmail).toString(),
        );
        if (profile.fullName.isNotEmpty) {
          _currentUser = profile;
          _registeredUsers[key] = _RegisteredAccount(
            profile: profile,
            password: password,
          );
          notifyListeners();
          await DatabaseHelper.instance.saveUserProfile(profile);
          return null;
        }
      } else if (response.statusCode == 401) {
        return 'Email немесе құпиясөз қате';
      }
    } catch (_) {}

    // 3. Fallback: if logging in with a new email not yet in local store,
    // update current user email & derive name if different from current user.
    if (_currentUser.email.toLowerCase() != key) {
      final localPart = cleanEmail.split('@').first;
      final formattedName = localPart.isNotEmpty
          ? '${localPart[0].toUpperCase()}${localPart.substring(1)}'
          : 'Студент';
      final profile = UserProfile(
        fullName: formattedName,
        university: _currentUser.university,
        email: cleanEmail,
      );
      _currentUser = profile;
      _registeredUsers[key] = _RegisteredAccount(
        profile: profile,
        password: password,
      );
      notifyListeners();
      await DatabaseHelper.instance.saveUserProfile(profile);
    }

    return null;
  }
}


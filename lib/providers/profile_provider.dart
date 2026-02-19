import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileProvider extends ChangeNotifier {
  final UserProfile _profile = UserProfile(
    username: 'Player1',
    avatarUrl: '',
  );

  UserProfile get profile => _profile;

  void updateUsername(String username) {
    _profile.username = username;
    notifyListeners();
  }

  void updateAvatar(String url) {
    _profile.avatarUrl = url;
    notifyListeners();
  }
}

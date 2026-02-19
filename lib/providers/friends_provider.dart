import 'package:flutter/material.dart';
import '../models/friend.dart';

class FriendsProvider extends ChangeNotifier {
  final List<Friend> _friends = [
    Friend(
      id: '1',
      username: 'GamerAlex',
      avatarUrl: '',
      status: FriendStatus.accepted,
    ),
    Friend(
      id: '2',
      username: 'PixelQueen',
      avatarUrl: '',
      status: FriendStatus.accepted,
    ),
    Friend(
      id: '3',
      username: 'NightOwlGaming',
      avatarUrl: '',
      status: FriendStatus.pending,
    ),
    Friend(
      id: '4',
      username: 'SpeedRunner42',
      avatarUrl: '',
      status: FriendStatus.suggested,
    ),
    Friend(
      id: '5',
      username: 'CasualCrafter',
      avatarUrl: '',
      status: FriendStatus.suggested,
    ),
    Friend(
      id: '6',
      username: 'RPGLegend',
      avatarUrl: '',
      status: FriendStatus.suggested,
    ),
  ];

  List<Friend> get friends =>
      _friends.where((f) => f.status == FriendStatus.accepted).toList();
  List<Friend> get pendingRequests =>
      _friends.where((f) => f.status == FriendStatus.pending).toList();
  List<Friend> get suggestions =>
      _friends.where((f) => f.status == FriendStatus.suggested).toList();

  void acceptRequest(String id) {
    final friend = _friends.firstWhere((f) => f.id == id);
    friend.status = FriendStatus.accepted;
    notifyListeners();
  }

  void declineRequest(String id) {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void addFriend(String id) {
    final index = _friends.indexWhere((f) => f.id == id);
    if (index >= 0) {
      _friends[index].status = FriendStatus.pending;
    }
    notifyListeners();
  }

  void removeFriend(String id) {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  List<Friend> searchFriends(String query) {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _friends
        .where((f) => f.username.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

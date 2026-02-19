enum FriendStatus { pending, accepted, suggested }

class Friend {
  final String id;
  final String username;
  final String avatarUrl;
  FriendStatus status;

  Friend({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    this.status = FriendStatus.suggested,
  });
}

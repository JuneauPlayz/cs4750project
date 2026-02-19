import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: false,
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, provider, child) {
          final friends = provider.friends;
          final requests = provider.pendingRequests;
          final suggestions = provider.suggestions;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (requests.isNotEmpty) ...[
                _buildHeader(context, 'Friend Requests'),
                ...requests.map((f) => _buildRequestTile(context, f, provider)),
                const Divider(),
              ],
              
              _buildHeader(context, 'My Friends (${friends.length})'),
              if (friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('You haven\'t added any friends yet.'),
                )
              else
                ...friends.map((f) => _buildFriendTile(context, f)),
              
              const Divider(),
              _buildHeader(context, 'Recommended Friends'),
              ...suggestions.map((f) => _buildSuggestionTile(context, f, provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, Friend friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(friend.username[0].toUpperCase()),
      ),
      title: Text(friend.username),
      subtitle: const Text('Online'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Future: Navigate to friend profile
      },
    );
  }

  Widget _buildRequestTile(BuildContext context, Friend friend, FriendsProvider provider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        child: Text(friend.username[0].toUpperCase()),
      ),
      title: Text(friend.username),
      subtitle: const Text('wants to be your friend'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => provider.acceptRequest(friend.id),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => provider.declineRequest(friend.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, Friend friend, FriendsProvider provider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(friend.username[0].toUpperCase()),
      ),
      title: Text(friend.username),
      subtitle: const Text('Similar taste in games'),
      trailing: TextButton(
        onPressed: () => provider.addFriend(friend.id),
        child: const Text('Add'),
      ),
    );
  }
}

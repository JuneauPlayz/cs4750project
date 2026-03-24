import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';

class GameOnboardingScreen extends StatefulWidget {
  const GameOnboardingScreen({super.key});

  @override
  State<GameOnboardingScreen> createState() => _GameOnboardingScreenState();
}

class _GameOnboardingScreenState extends State<GameOnboardingScreen> {
  final _titleController = TextEditingController();
  final _conceptController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titleController.text.isNotEmpty) return;

    final userName = context.read<AuthProvider>().currentUser?.name.trim();
    if (userName != null && userName.isNotEmpty) {
      _titleController.text = '$userName\'s Game';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_conceptController.text.trim().isEmpty) return;

    context.read<ProjectProvider>().saveProjectProfile(
      title: _titleController.text,
      conceptDescription: _conceptController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = context.watch<AuthProvider>().currentUser?.name;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.sports_esports_outlined,
                          color: colorScheme.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        userName == null || userName.isEmpty
                            ? 'Tell us about your game'
                            : 'Welcome, $userName',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Describe your game in a few sentences. We will use AI to find modern comparable games and tailor the discovery feed.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _titleController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Game Title',
                          prefixIcon: Icon(Icons.videogame_asset_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Describe your game in a few sentences.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _conceptController,
                        minLines: 4,
                        maxLines: 6,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText:
                              'Example: A cozy co-op survival crafting game where two players run a magical tea shop in a haunted forest.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_conceptController.text.trim().isEmpty)
                        Text(
                          'Add a short description to continue.',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _conceptController.text.trim().isEmpty
                            ? null
                            : _continue,
                        child: const Text('Continue to My Feed'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

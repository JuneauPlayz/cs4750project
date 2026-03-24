import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider authProvider) async {
    final isCreateAccount = authProvider.mode == AuthMode.createAccount;

    authProvider.clearError();
    if (!_formKey.currentState!.validate()) return;

    final success = isCreateAccount
        ? await authProvider.createAccount(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await authProvider.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted || !success) return;

    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _submitGoogle(AuthProvider authProvider) async {
    authProvider.clearError();
    final success = await authProvider.signInWithGoogle();
    if (!mounted || !success) return;

    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _onModeChanged(AuthProvider authProvider, AuthMode mode) {
    authProvider.setMode(mode);
    _passwordController.clear();
    _confirmPasswordController.clear();
    if (mode == AuthMode.signIn) {
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final isCreateAccount =
                      authProvider.mode == AuthMode.createAccount;

                  return Card(
                    color: colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.lock_person_outlined,
                                color: colorScheme.primary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'GameDevLens',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isCreateAccount
                                  ? 'Create an account so we can connect your project data to a backend next.'
                                  : 'Sign in to continue building and reviewing your game ideas.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SegmentedButton<AuthMode>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment<AuthMode>(
                                  value: AuthMode.signIn,
                                  label: Text('Sign In'),
                                ),
                                ButtonSegment<AuthMode>(
                                  value: AuthMode.createAccount,
                                  label: Text('Create Account'),
                                ),
                              ],
                              selected: {authProvider.mode},
                              onSelectionChanged: (selection) {
                                _onModeChanged(authProvider, selection.first);
                              },
                            ),
                            const SizedBox(height: 24),
                            if (isCreateAccount) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (!isCreateAccount) return null;
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter your name.';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Use at least 2 characters.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Enter your email.';
                                }
                                if (!trimmed.contains('@') ||
                                    !trimmed.contains('.')) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: isCreateAccount
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password.';
                                }
                                if (value.length < 8) {
                                  return 'Use at least 8 characters.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (!isCreateAccount) {
                                  _submit(authProvider);
                                }
                              },
                            ),
                            if (isCreateAccount) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                ),
                                validator: (value) {
                                  if (!isCreateAccount) return null;
                                  if (value == null || value.isEmpty) {
                                    return 'Confirm your password.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(authProvider),
                              ),
                            ],
                            if (authProvider.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer.withValues(
                                    alpha: 0.6,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: authProvider.isSubmitting
                                  ? null
                                  : () => _submit(authProvider),
                              child: authProvider.isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isCreateAccount
                                          ? 'Create Account'
                                          : 'Sign In',
                                    ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: authProvider.isSubmitting
                                  ? null
                                  : () => _submitGoogle(authProvider),
                              icon: const Icon(Icons.login),
                              label: const Text('Continue with Google'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: authProvider.isSubmitting
                                  ? null
                                  : () => _onModeChanged(
                                      authProvider,
                                      isCreateAccount
                                          ? AuthMode.signIn
                                          : AuthMode.createAccount,
                                    ),
                              child: Text(
                                isCreateAccount
                                    ? 'Already have an account? Sign in'
                                    : 'Need an account? Create one',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

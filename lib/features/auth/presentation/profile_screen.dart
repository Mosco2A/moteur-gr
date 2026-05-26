import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/auth_service.dart';
import '../providers/auth_provider.dart';

/// Écran de profil utilisateur.
///
/// Affiche l'identité, permet de se connecter via Google,
/// de se déconnecter ou de supprimer son compte.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (user) => _buildProfile(context, ref, theme, user),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AuthUser? user,
  ) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Avatar
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: user.isAnonymous
                ? Icon(Icons.person, size: 48,
                    color: theme.colorScheme.primary)
                : Text(
                    (user.displayName ?? 'U')[0].toUpperCase(),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingBase),

        // Nom
        Center(
          child: Text(
            user.isAnonymous
                ? 'Randonneur anonyme'
                : user.displayName ?? 'Utilisateur',
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Méthode d'auth
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              'Connecté via ${user.authMethod.label}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXl),

        // Connexion Google (si anonyme)
        if (user.isAnonymous) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Se connecter avec Google'),
              subtitle: const Text(
                  'Pour sauvegarder votre progression'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final service = ref.read(authServiceProvider);
                await service.signInWithGoogleSilent();
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        // Déconnexion (si identifié)
        if (!user.isAnonymous) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              subtitle: const Text('Revenir en mode anonyme'),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],

        // Supprimer le compte
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_forever,
                color: AppTheme.rougeUrgence),
            title: const Text(
              'Supprimer mon compte',
              style: TextStyle(color: AppTheme.rougeUrgence),
            ),
            subtitle: const Text(
                'Toutes vos données seront effacées'),
            onTap: () => _confirmDelete(context, ref),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous reviendrez en mode anonyme. '
            'Vos données locales sont conservées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              Navigator.pop(context);
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Text(
            'Cette action est irréversible. '
            'Toutes vos données, notes et progression seront effacées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rougeUrgence,
            ),
            onPressed: () {
              ref.read(authServiceProvider).deleteAccount();
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

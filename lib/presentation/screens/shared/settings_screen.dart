import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _sectionTitle('Apparence'),
          Card(
            child: ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? AppColors.primary : AppColors.accent,
              ),
              title: const Text('Mode Sombre', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(isDark ? 'Activé' : 'Désactivé', style: const TextStyle(fontSize: 12)),
              trailing: Switch(
                value: isDark,
                activeColor: AppColors.primary,
                onChanged: (_) => themeNotifier.toggleTheme(),
              ),
              onTap: () => themeNotifier.toggleTheme(),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Compte'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  Navigator.of(context).pop();
                  await ref.read(authStateProvider.notifier).logout();
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'SchoolFlow v1.0 — Système Scolaire CI',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
      ),
    );
  }
}

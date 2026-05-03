import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'message_dialog.dart';
import 'teacher_profile_dialog.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Espace Professeur', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionCard(
            context,
            title: 'Saisir des notes',
            icon: Icons.edit_document,
            color: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Ajouter un devoir',
            icon: Icons.assignment_add,
            color: AppColors.secondary,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Cahier de texte',
            icon: Icons.book,
            color: AppColors.accent,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Messagerie',
            icon: Icons.message,
            color: AppColors.info,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const MessageDialog(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            title: 'Mon Profil (Matière & Classes)',
            icon: Icons.person,
            color: AppColors.secondary,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const TeacherProfileDialog(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

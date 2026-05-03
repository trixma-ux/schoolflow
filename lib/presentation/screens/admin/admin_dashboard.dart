import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'add_user_dialog.dart';
import 'link_student_dialog.dart';
import 'class_management_tab.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _SystemOverviewTab(adminId: user.id),
      const _UserManagementTab(),
      const ClassManagementTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Administration', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              heroTag: 'add_user_fab',
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const AddUserDialog(),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Vue Globale'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Utilisateurs'),
          NavigationDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: 'Classes'),
        ],
      ),
    );
  }
}

class _SystemOverviewTab extends ConsumerStatefulWidget {
  final String adminId;

  const _SystemOverviewTab({required this.adminId});

  @override
  ConsumerState<_SystemOverviewTab> createState() => _SystemOverviewTabState();
}

class _SystemOverviewTabState extends ConsumerState<_SystemOverviewTab> {
  bool _seeding = false;

  Future<void> _seedSubjects() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    if (firestore == null) return;

    setState(() => _seeding = true);
    try {
      final existing = await firestore.collection('subjects').get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les matières sont déjà initialisées.'), backgroundColor: AppColors.info),
          );
        }
        setState(() => _seeding = false);
        return;
      }

      final subjects = [
        {'id': 'sub_maths', 'name': 'Mathématiques', 'coefficient': 4.0, 'description': 'Analyse, algèbre, géométrie'},
        {'id': 'sub_physics', 'name': 'Physique-Chimie', 'coefficient': 3.0, 'description': 'Sciences physiques et chimie'},
        {'id': 'sub_svt', 'name': 'SVT', 'coefficient': 2.0, 'description': 'Sciences de la Vie et de la Terre'},
        {'id': 'sub_french', 'name': 'Français', 'coefficient': 3.0, 'description': 'Langue et littérature françaises'},
        {'id': 'sub_philo', 'name': 'Philosophie', 'coefficient': 3.0, 'description': 'Philosophie et éthique'},
        {'id': 'sub_history', 'name': 'Histoire-Géographie', 'coefficient': 3.0, 'description': 'Histoire et géographie'},
        {'id': 'sub_english', 'name': 'Anglais', 'coefficient': 3.0, 'description': 'Langue anglaise'},
        {'id': 'sub_spanish', 'name': 'Espagnol', 'coefficient': 2.0, 'description': 'Langue espagnole'},
        {'id': 'sub_eco', 'name': 'SES', 'coefficient': 3.0, 'description': 'Sciences Économiques et Sociales'},
        {'id': 'sub_eps', 'name': 'EPS', 'coefficient': 2.0, 'description': 'Éducation Physique et Sportive'},
      ];

      final batch = firestore.batch();
      for (final s in subjects) {
        final ref = firestore.collection('subjects').doc(s['id'] as String);
        batch.set(ref, {
          'name': s['name'],
          'coefficient': s['coefficient'],
          'description': s['description'],
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('10 matières initialisées avec succès !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final users = usersAsync.valueOrNull ?? [];
    final studentCount = users.where((u) => u.role == UserRole.student).length;
    final teacherCount = users.where((u) => u.role == UserRole.teacher).length;
    final parentCount = users.where((u) => u.role == UserRole.parent).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Row 1
        Row(
          children: [
            Expanded(child: _buildKPI(context, 'Élèves', '$studentCount', Icons.person, AppColors.info)),
            const SizedBox(width: 12),
            Expanded(child: _buildKPI(context, 'Professeurs', '$teacherCount', Icons.badge, AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: classesAsync.when(
                data: (classes) => _buildKPI(context, 'Classes', '${classes.length}', Icons.class_, AppColors.warning),
                loading: () => _buildKPI(context, 'Classes', '...', Icons.class_, AppColors.warning),
                error: (_, __) => _buildKPI(context, 'Classes', '!', Icons.class_, AppColors.error),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildKPI(context, 'Parents', '$parentCount', Icons.family_restroom, AppColors.accent)),
          ],
        ),
        const SizedBox(height: 24),

        // Initialization section
        subjectsAsync.when(
          data: (subjects) => subjects.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info),
                          SizedBox(width: 8),
                          Text('Première utilisation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Initialisez les matières pour que les professeurs et élèves puissent accéder à toutes les fonctionnalités.'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _seeding ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_fix_high),
                          label: Text(_seeding ? 'Initialisation...' : 'Initialiser les matières (10)'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white),
                          onPressed: _seeding ? null : _seedSubjects,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),
        Text('Actions Rapides', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        _actionTile(
          context,
          icon: Icons.person_add,
          color: AppColors.primary,
          title: 'Ajouter un utilisateur',
          onTap: () => showDialog(context: context, builder: (_) => const AddUserDialog()),
        ),
        const SizedBox(height: 8),
        _actionTile(
          context,
          icon: Icons.auto_fix_high,
          color: AppColors.secondary,
          title: 'Initialiser / Réinitialiser les matières',
          onTap: _seeding ? () {} : _seedSubjects,
        ),
        const SizedBox(height: 8),
        _actionTile(
          context,
          icon: Icons.class_,
          color: AppColors.warning,
          title: 'Gérer les classes',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildKPI(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, {required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _UserManagementTab extends ConsumerWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 72, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucun utilisateur.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter un utilisateur'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: () => showDialog(context: context, builder: (_) => const AddUserDialog()),
                ),
              ],
            ),
          );
        }

        // Group by role
        final byRole = <UserRole, List<UserModel>>{};
        for (final u in users) {
          byRole.putIfAbsent(u.role, () => []).add(u);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final role in [UserRole.admin, UserRole.teacher, UserRole.student, UserRole.parent])
              if ((byRole[role] ?? []).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    _roleLabel(role),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                ...byRole[role]!.map((user) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _roleColor(role).withValues(alpha: 0.15),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
                    trailing: user.role == UserRole.parent
                        ? IconButton(
                            icon: const Icon(Icons.link, color: AppColors.primary),
                            tooltip: 'Lier un élève',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => LinkStudentDialog(parentId: user.id, parentName: user.name),
                            ),
                          )
                        : _roleBadge(role),
                  ),
                )),
              ],
          ],
        );
      },
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'ADMINISTRATEURS';
      case UserRole.teacher: return 'PROFESSEURS';
      case UserRole.student: return 'ÉLÈVES';
      case UserRole.parent: return 'PARENTS';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return AppColors.error;
      case UserRole.teacher: return AppColors.secondary;
      case UserRole.student: return AppColors.info;
      case UserRole.parent: return AppColors.accent;
    }
  }

  Widget _roleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(fontSize: 11, color: _roleColor(role), fontWeight: FontWeight.bold),
      ),
    );
  }
}

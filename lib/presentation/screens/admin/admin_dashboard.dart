import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import 'add_user_dialog.dart';
import 'link_student_dialog.dart';

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
      _SystemOverviewTab(),
      _UserManagementTab(),
      const Center(child: Text('Gestion Classes')),
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
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddUserDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

class _SystemOverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildKPI(context, 'Élèves', 'N/D', Icons.person, AppColors.info)),
            const SizedBox(width: 16),
            Expanded(child: _buildKPI(context, 'Professeurs', 'N/D', Icons.badge, AppColors.secondary)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: classesAsync.when(
                data: (classes) => _buildKPI(context, 'Classes', '${classes.length}', Icons.meeting_room, AppColors.warning),
                loading: () => _buildKPI(context, 'Classes', '...', Icons.meeting_room, AppColors.warning),
                error: (e,s) => _buildKPI(context, 'Classes', 'Erreur', Icons.meeting_room, AppColors.error),
              )
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildKPI(context, 'Absences (J)', '0', Icons.warning_amber, AppColors.error)),
          ],
        ),
        const SizedBox(height: 32),
        Text('Actions Rapides', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person_add, color: AppColors.primary),
          title: const Text('Ajouter un utilisateur'),
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const AddUserDialog(),
            );
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.analytics, color: AppColors.secondary),
          title: const Text('Générer les bulletins'),
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildKPI(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _UserManagementTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('Aucun utilisateur trouvé.'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary)),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.email} - ${user.role.name}'),
                trailing: user.role == UserRole.parent ? IconButton(
                  icon: const Icon(Icons.link, color: AppColors.textSecondary),
                  tooltip: 'Lier un élève',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => LinkStudentDialog(
                        parentId: user.id,
                        parentName: user.name,
                      ),
                    );
                  },
                ) : const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }
}

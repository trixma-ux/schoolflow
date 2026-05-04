import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/data/filieres_ci.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../core/theme/app_colors.dart';
import '../shared/profile_screen.dart';
import '../shared/settings_screen.dart';
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

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unread = ref.watch(unreadNotificationsCountProvider(user.id));

    final pages = [
      _SystemOverviewTab(adminId: user.id, onNavigateToTab: _goToTab),
      const _UserManagementTab(),
      const ClassManagementTab(),
      const _ComplaintsTab(),
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
              if (unread > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Paramètres',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              heroTag: 'add_user_fab',
              onPressed: () => showDialog(context: context, builder: (context) => const AddUserDialog()),
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
          NavigationDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: 'Plaintes'),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _SystemOverviewTab extends ConsumerStatefulWidget {
  final String adminId;
  final void Function(int) onNavigateToTab;
  const _SystemOverviewTab({required this.adminId, required this.onNavigateToTab});

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
      final batch = firestore.batch();
      int count = 0;

      for (final filiere in filieresCi) {
        for (final subj in filiere.subjects) {
          final ref2 = firestore.collection('subjects').doc(subj.id);
          batch.set(ref2, {
            'name': subj.name,
            'coefficient': subj.coefficient,
            'description': '${filiere.name} — coeff. ${subj.coefficient}',
            'filiere': filiere.id,
          });
          count++;
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count matières CI initialisées !'), backgroundColor: AppColors.success),
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
        Row(children: [
          Expanded(child: _buildKPI('Élèves', '$studentCount', Icons.person, AppColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _buildKPI('Professeurs', '$teacherCount', Icons.badge, AppColors.secondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: classesAsync.when(
            data: (c) => _buildKPI('Classes', '${c.length}', Icons.class_, AppColors.warning),
            loading: () => _buildKPI('Classes', '...', Icons.class_, AppColors.warning),
            error: (_, __) => _buildKPI('Classes', '!', Icons.class_, AppColors.error),
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildKPI('Parents', '$parentCount', Icons.family_restroom, AppColors.accent)),
        ]),
        const SizedBox(height: 24),

        subjectsAsync.when(
          data: (subjects) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.book, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(subjects.isEmpty ? 'Matières non initialisées' : '${subjects.length} matières (${filieresCi.length} filières CI)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
                ]),
                const SizedBox(height: 8),
                Text(subjects.isEmpty
                    ? 'Initialisez les matières pour que les professeurs puissent configurer leur profil.'
                    : 'Filières : ${filieresCi.map((f) => f.name).join(', ')}',
                  style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _seeding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_fix_high),
                    label: Text(_seeding ? 'Initialisation...' : (subjects.isEmpty ? 'Initialiser les matières CI' : 'Réinitialiser les matières CI')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white),
                    onPressed: _seeding ? null : _seedSubjects,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),
        Text('Actions Rapides', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _actionTile(Icons.person_add, AppColors.primary, 'Ajouter un utilisateur',
          () => showDialog(context: context, builder: (_) => const AddUserDialog())),
        const SizedBox(height: 8),
        _actionTile(Icons.class_, AppColors.warning, 'Gérer les classes', () => widget.onNavigateToTab(2)),
      ],
    );
  }

  Widget _buildKPI(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _actionTile(IconData icon, Color color, String title, VoidCallback onTap) {
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

// ─── User Management Tab ──────────────────────────────────────────────────────

class _UserManagementTab extends ConsumerWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (users) {
        if (users.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.people_outline, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Aucun utilisateur.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => const AddUserDialog()),
            ),
          ]));
        }

        final byRole = <UserRole, List<UserModel>>{};
        for (final u in users) byRole.putIfAbsent(u.role, () => []).add(u);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final role in [UserRole.admin, UserRole.teacher, UserRole.student, UserRole.parent])
              if ((byRole[role] ?? []).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(_roleLabel(role),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email, style: const TextStyle(fontSize: 12)),
                        if (role == UserRole.teacher && user.filiere != null)
                          Text(_filiereLabel(user.filiere!), style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                    isThreeLine: role == UserRole.teacher && user.filiere != null,
                    trailing: user.role == UserRole.parent
                        ? IconButton(
                            icon: const Icon(Icons.link, color: AppColors.primary),
                            tooltip: 'Lier un élève',
                            onPressed: () => showDialog(context: context,
                              builder: (_) => LinkStudentDialog(parentId: user.id, parentName: user.name)),
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

  String _filiereLabel(String id) {
    try {
      final f = filieresCi.firstWhere((f) => f.id == id);
      return '${f.name} — ${f.description}';
    } catch (_) {
      return id;
    }
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
      decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(role.name.toUpperCase(), style: TextStyle(fontSize: 11, color: _roleColor(role), fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Complaints Tab ────────────────────────────────────────────────────────────

class _ComplaintsTab extends ConsumerWidget {
  const _ComplaintsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return complaintsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (complaints) {
        if (complaints.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 72, color: AppColors.success),
            SizedBox(height: 16),
            Text('Aucune plainte en cours.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ]));
        }

        final pending = complaints.where((c) => c.status == 'pending').toList();
        final resolved = complaints.where((c) => c.status != 'pending').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              Row(children: [
                const Icon(Icons.pending_outlined, color: AppColors.warning, size: 16),
                const SizedBox(width: 6),
                Text('EN ATTENTE (${pending.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning)),
              ]),
              const SizedBox(height: 8),
              ...pending.map((c) => _complaintCard(context, ref, c, subjects)),
              const SizedBox(height: 20),
            ],
            if (resolved.isNotEmpty) ...[
              const Text('TRAITÉES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...resolved.map((c) => _complaintCard(context, ref, c, subjects)),
            ],
          ],
        );
      },
    );
  }

  Widget _complaintCard(BuildContext context, WidgetRef ref, ComplaintModel c, List subjects) {
    final statusColor = c.status == 'pending' ? AppColors.warning : c.status == 'resolved' ? AppColors.success : AppColors.error;
    final statusLabel = c.status == 'pending' ? 'En attente' : c.status == 'resolved' ? 'Résolu' : 'Rejeté';
    final typeLabel = c.type == 'grade' ? 'Note' : c.type == 'absence' ? 'Absence' : 'Autre';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: c.status == 'pending' ? () => _showReplyDialog(context, ref, c) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(typeLabel, style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(DateFormat('dd/MM/yy').format(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 8),
            Text(c.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(c.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (c.adminResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text(c.adminResponse!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ]),
              ),
            ],
            if (c.status == 'pending') ...[
              const SizedBox(height: 8),
              const Text('Appuyez pour répondre →', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ]),
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, ComplaintModel c) {
    final replyCtrl = TextEditingController();
    String selectedStatus = 'resolved';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Répondre à ${c.studentName}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(c.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Votre réponse', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Résoudre'),
                  selected: selectedStatus == 'resolved',
                  selectedColor: AppColors.success.withValues(alpha: 0.15),
                  onSelected: (_) => setS(() => selectedStatus = 'resolved'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Rejeter'),
                  selected: selectedStatus == 'rejected',
                  selectedColor: AppColors.error.withValues(alpha: 0.15),
                  onSelected: (_) => setS(() => selectedStatus = 'rejected'),
                ),
              ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: selectedStatus == 'resolved' ? AppColors.success : AppColors.error),
              onPressed: () async {
                final firestore = ref.read(firebaseFirestoreProvider);
                await firestore?.collection('complaints').doc(c.id).update({
                  'status': selectedStatus,
                  'adminResponse': replyCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plainte ${selectedStatus == 'resolved' ? 'résolue' : 'rejetée'} !'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

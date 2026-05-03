import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/grade_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../shared/profile_screen.dart';
import '../shared/settings_screen.dart';
import 'message_dialog.dart';
import 'teacher_profile_dialog.dart';
import 'grade_entry_dialog.dart';
import 'assignment_dialog.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final unread = ref.watch(unreadNotificationsCountProvider(user.id));
    final classIds = user.classIds ?? [];

    final pages = [
      _ActionsTab(teacherId: user.id, classIds: classIds),
      _GradesTab(teacherId: user.id),
      _ClassMembersTab(teacher: user),
      _NotificationsTab(userId: user.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Espace Professeur', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined), tooltip: 'Notifications', onPressed: () {}),
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
              heroTag: 'teacher_grade_fab',
              onPressed: () => showDialog(context: context, builder: (_) => const GradeEntryDialog()),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.grade_outlined), selectedIcon: Icon(Icons.grade), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Élèves'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Messages'),
        ],
      ),
    );
  }
}

// ─── Actions Tab ─────────────────────────────────────────────────────────────

class _ActionsTab extends ConsumerWidget {
  final String teacherId;
  final List<String> classIds;

  const _ActionsTab({required this.teacherId, required this.classIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (classIds.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profil incomplet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                      const SizedBox(height: 4),
                      const Text('Configurez votre filière, vos matières et classes.', style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => showDialog(context: context, builder: (_) => const TeacherProfileDialog()),
                        child: const Text('Configurer mon profil →'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        classesAsync.when(
          data: (allClasses) {
            final myClasses = allClasses.where((c) => classIds.contains(c.id)).toList();
            if (myClasses.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes Classes', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...myClasses.map((c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.class_, color: AppColors.primary),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.studentIds.length} élève(s) • ${c.academicYear}'),
                  ),
                )),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        Text('Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        _buildActionCard(context, title: 'Saisir des notes', subtitle: 'Enregistrer une évaluation', icon: Icons.edit_document, color: AppColors.primary,
          onTap: () => showDialog(context: context, builder: (_) => const GradeEntryDialog())),
        const SizedBox(height: 12),
        _buildActionCard(context, title: 'Publier un devoir', subtitle: 'Ajouter un travail à rendre', icon: Icons.assignment_add, color: AppColors.secondary,
          onTap: () => showDialog(context: context, builder: (_) => const AssignmentDialog())),
        const SizedBox(height: 12),
        _buildActionCard(context, title: 'Envoyer un message', subtitle: 'Contacter un parent ou l\'admin', icon: Icons.message, color: AppColors.info,
          onTap: () => showDialog(context: context, builder: (_) => const MessageDialog())),
        const SizedBox(height: 12),
        _buildActionCard(context, title: 'Mon profil & classes', subtitle: 'Gérer ma filière, matières et classes', icon: Icons.person, color: AppColors.accent,
          onTap: () => showDialog(context: context, builder: (_) => const TeacherProfileDialog())),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title, required String subtitle,
    required IconData icon, required Color color, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Grades Tab ───────────────────────────────────────────────────────────────

class _GradesTab extends ConsumerWidget {
  final String teacherId;
  const _GradesTab({required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(teacherGradesProvider(teacherId));
    final users = ref.watch(allUsersProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return gradesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (grades) {
        if (grades.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.grade_outlined, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Aucune note saisie.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add), label: const Text('Saisir une note'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => const GradeEntryDialog()),
            ),
          ]));
        }

        final sorted = [...grades]..sort((a, b) => b.date.compareTo(a.date));

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Text('${sorted.length} note(s)', style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                onPressed: () => showDialog(context: context, builder: (_) => const GradeEntryDialog()),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final g = sorted[i];
                final student = _findUser(users, g.studentId);
                final subject = _findSubject(subjects, g.subjectId);
                final ratio = g.score / g.maxScore;
                final color = ratio >= 0.5 ? AppColors.success : AppColors.error;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text(
                        g.score == g.score.roundToDouble() ? g.score.toStringAsFixed(0) : g.score.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                      ),
                    ),
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${subject.name} • ${_typeName(g.type)} • ${DateFormat('dd/MM/yy').format(g.date)}'),
                    trailing: Text('/${g.maxScore.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}

// ─── Class Members Tab ────────────────────────────────────────────────────────

class _ClassMembersTab extends ConsumerWidget {
  final UserModel teacher;
  const _ClassMembersTab({required this.teacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final classes = classesAsync.valueOrNull ?? [];
    final allUsers = usersAsync.valueOrNull ?? [];
    final myClasses = classes.where((c) => (teacher.classIds ?? []).contains(c.id)).toList();

    if (myClasses.isEmpty) {
      return const Center(child: Text('Aucune classe assignée.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return DefaultTabController(
      length: myClasses.length,
      child: Column(
        children: [
          TabBar(isScrollable: true, tabs: myClasses.map((c) => Tab(text: c.name)).toList()),
          Expanded(
            child: TabBarView(
              children: myClasses.map((cls) {
                final students = allUsers.where((u) => u.role == UserRole.student && cls.studentIds.contains(u.id)).toList();
                if (students.isEmpty) {
                  return const Center(child: Text('Aucun élève dans cette classe.', style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.info.withValues(alpha: 0.15),
                        child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(s.name),
                      subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notifications Tab ────────────────────────────────────────────────────────

class _NotificationsTab extends ConsumerWidget {
  final String userId;
  const _NotificationsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider(userId));

    return notifsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (notifs) {
        if (notifs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox_outlined, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Aucun message.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.send), label: const Text('Envoyer un message'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => const MessageDialog()),
            ),
          ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifs.length,
          itemBuilder: (context, i) {
            final n = notifs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: n.isRead ? null : AppColors.primaryLight.withValues(alpha: 0.05),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(n.type == NotificationType.grade ? Icons.grade : Icons.message,
                    color: AppColors.primary, size: 20),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(DateFormat('dd/MM\nHH:mm').format(n.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.right),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserModel _findUser(List<UserModel> users, String id) {
  try { return users.firstWhere((u) => u.id == id); }
  catch (_) { return UserModel(id: id, name: 'Élève inconnu', email: '', role: UserRole.student, profilePic: '', createdAt: DateTime.now()); }
}

SubjectModel _findSubject(List<SubjectModel> subjects, String id) {
  try { return subjects.firstWhere((s) => s.id == id); }
  catch (_) { return SubjectModel(id: id, name: id, coefficient: 1, description: '', filiere: ''); }
}

String _typeName(GradeType type) {
  switch (type) {
    case GradeType.exam: return 'Examen';
    case GradeType.quiz: return 'Interrogation';
    case GradeType.homework: return 'Devoir Maison';
  }
}

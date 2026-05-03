import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/communication_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../shared/profile_screen.dart';
import '../shared/settings_screen.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final studentIds = user.studentIds ?? [];
    final unread = ref.watch(unreadNotificationsCountProvider(user.id));

    final pages = [
      _ChildrenTab(studentIds: studentIds),
      _MessagesTab(userId: user.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name.split(' ').first}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Espace Parent', style: Theme.of(context).textTheme.bodySmall),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: 'Mes Enfants'),
          NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }
}

// ─── Children Tab ─────────────────────────────────────────────────────────────

class _ChildrenTab extends ConsumerWidget {
  final List<String> studentIds;
  const _ChildrenTab({required this.studentIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (studentIds.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.family_restroom, size: 72, color: AppColors.textSecondary),
        SizedBox(height: 16),
        Text('Aucun enfant associé à ce compte.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16), textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text('Contactez l\'administration pour lier votre enfant.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: studentIds.length,
      itemBuilder: (context, index) => _ChildOverviewCard(studentId: studentIds[index]),
    );
  }
}

class _ChildOverviewCard extends ConsumerWidget {
  final String studentId;
  const _ChildOverviewCard({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(studentGradesProvider(studentId));
    final usersAsync = ref.watch(allUsersProvider);
    final classesAsync = ref.watch(classesProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    final allUsers = usersAsync.valueOrNull ?? [];
    UserModel? student;
    try { student = allUsers.firstWhere((u) => u.id == studentId); } catch (_) {}

    final allClasses = classesAsync.valueOrNull ?? [];
    String className = '';
    if (student?.classId != null) {
      try { className = allClasses.firstWhere((c) => c.id == student!.classId).name; } catch (_) {}
    }

    return gradesAsync.when(
      data: (grades) {
        double totalScore = 0;
        for (final g in grades) totalScore += (g.score / g.maxScore) * 20;
        final avg = grades.isEmpty ? 0.0 : totalScore / grades.length;
        final avgColor = avg >= 10 ? AppColors.success : AppColors.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  radius: 24,
                  child: Text(
                    student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student?.name ?? 'Élève inconnu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  if (className.isNotEmpty)
                    Text(className, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ])),
              ]),
              const Divider(height: 28),

              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Moyenne', grades.isEmpty ? 'N/A' : '${avg.toStringAsFixed(1)}/20', avgColor),
                _stat('Notes', '${grades.length}', AppColors.info),
                _stat('Absences', '0', AppColors.success),
              ]),

              if (grades.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Dernières notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ...([...grades]..sort((a, b) => b.date.compareTo(a.date))).take(3).map((g) {
                  final subjectName = _subjectName(subjects, g.subjectId);
                  final color = g.score / g.maxScore >= 0.5 ? AppColors.success : AppColors.error;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: Text(
                        g.score == g.score.roundToDouble() ? g.score.toStringAsFixed(0) : g.score.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    title: Text(subjectName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(g.date), style: const TextStyle(fontSize: 12)),
                    trailing: Text('/${g.maxScore.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }),
              ],
            ]),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Erreur: $e'))),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    ]);
  }
}

// ─── Messages Tab ─────────────────────────────────────────────────────────────

class _MessagesTab extends ConsumerWidget {
  final String userId;
  const _MessagesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider(userId));

    return notifsAsync.when(
      data: (notifs) {
        if (notifs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.inbox_outlined, size: 72, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Aucun message reçu.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifs.length,
          itemBuilder: (context, i) {
            final n = notifs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: n.isRead ? AppColors.surface : AppColors.primaryLight.withValues(alpha: 0.08),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    n.type == NotificationType.grade ? Icons.grade
                        : n.type == NotificationType.absence ? Icons.warning_amber
                        : Icons.message,
                    color: AppColors.primary, size: 18,
                  ),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(DateFormat('dd/MM/yyyy à HH:mm').format(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
                isThreeLine: true,
                onTap: () async {
                  if (!n.isRead) await CommunicationRepository().markAsRead(n.id);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _subjectName(List<SubjectModel> subjects, String id) {
  try { return subjects.firstWhere((s) => s.id == id).name; }
  catch (_) { return id; }
}

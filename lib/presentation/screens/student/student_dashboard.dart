import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/subject_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classId = user.classId ?? '';

    final pages = [
      _HomeTab(studentId: user.id, classId: classId),
      _AcademicTab(studentId: user.id),
      _ScheduleTab(classId: classId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name.split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Espace Élève', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.notifications_none),
              tooltip: 'Notifications',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
              backgroundColor: AppColors.primaryLight,
              radius: 18,
              child: user.profilePic.isEmpty
                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
          ),
        ],
      ),
      endDrawer: _NotificationsDrawer(userId: user.id),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Scolarité'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Planning'),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  final String studentId;
  final String classId;

  const _HomeTab({required this.studentId, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(classId));
    final schedulesAsync = ref.watch(classScheduleProvider(classId));
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // No-class warning
        if (classId.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(child: Text('Vous n\'êtes pas encore assigné à une classe. Contactez l\'administration.')),
              ],
            ),
          ),

        // Next class card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prochain Cours', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              schedulesAsync.when(
                data: (schedules) {
                  if (schedules.isEmpty) return const Text('Aucun cours prévu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
                  final next = schedules.first;
                  final subjectName = _subjectName(subjects, next.subjectId);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subjectName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text('${next.startTime} – ${next.endTime}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 16),
                          const Icon(Icons.room, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(next.room, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (e, _) => Text('$e', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Assignments
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Devoirs à rendre', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Aucun devoir pour le moment.', style: TextStyle(color: AppColors.textSecondary))),
              );
            }
            final sorted = [...assignments]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            return Column(
              children: sorted.map((a) {
                final subjectName = _subjectName(subjects, a.subjectId);
                final daysLeft = a.dueDate.difference(DateTime.now()).inDays;
                final urgentColor = daysLeft <= 2 ? AppColors.error : daysLeft <= 5 ? AppColors.warning : AppColors.success;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: urgentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(Icons.assignment, color: urgentColor),
                    ),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$subjectName • Pour le ${DateFormat('dd/MM/yyyy').format(a.dueDate)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: urgentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        daysLeft <= 0 ? 'Aujourd\'hui' : 'J-$daysLeft',
                        style: TextStyle(color: urgentColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur: $e'),
        ),
      ],
    );
  }
}

// ─── Academic Tab ─────────────────────────────────────────────────────────────

class _AcademicTab extends ConsumerWidget {
  final String studentId;

  const _AcademicTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(studentGradesProvider(studentId));
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return gradesAsync.when(
      data: (grades) {
        if (grades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grade_outlined, size: 72, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucune note pour le moment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ],
            ),
          );
        }

        // Compute average
        double total = 0;
        for (final g in grades) {
          total += (g.score / g.maxScore) * 20;
        }
        final avg = total / grades.length;

        final sorted = [...grades]..sort((a, b) => b.date.compareTo(a.date));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Average card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: (avg >= 10 ? AppColors.success : AppColors.error).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (avg >= 10 ? AppColors.success : AppColors.error).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(avg >= 10 ? Icons.trending_up : Icons.trending_down,
                      color: avg >= 10 ? AppColors.success : AppColors.error, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Moyenne Générale', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        '${avg.toStringAsFixed(2)}/20',
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold,
                          color: avg >= 10 ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text('${grades.length} note(s)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            Text('Toutes mes notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...sorted.map((g) {
              final subjectName = _subjectName(subjects, g.subjectId);
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
                  title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${_gradeTypeName(g.type.name)} • ${DateFormat('dd/MM/yyyy').format(g.date)}'),
                  trailing: Text('/${g.maxScore.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

// ─── Schedule Tab ─────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerWidget {
  final String classId;

  const _ScheduleTab({required this.classId});

  static const _dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleProvider(classId));
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return schedulesAsync.when(
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 72, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucun cours planifié.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('L\'emploi du temps sera ajouté par l\'administration.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        // Group by day
        final byDay = <int, List<dynamic>>{};
        for (final s in schedules) {
          byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
        }
        final sortedDays = byDay.keys.toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mon Emploi du Temps', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final day in sortedDays) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  _dayNames[day],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                ),
              ),
              ...byDay[day]!.map((s) {
                final subjectName = _subjectName(subjects, s.subjectId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(s.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(s.endTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.room, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(s.room, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}

// ─── Notifications Drawer ─────────────────────────────────────────────────────

class _NotificationsDrawer extends ConsumerWidget {
  final String userId;

  const _NotificationsDrawer({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider(userId));

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: notifsAsync.when(
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('Aucune notification.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (ctx, i) {
                    final n = notifs[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          n.type == NotificationType.grade ? Icons.grade
                              : n.type == NotificationType.assignment ? Icons.assignment
                              : Icons.message,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                      subtitle: Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      trailing: Text(DateFormat('dd/MM\nHH:mm').format(n.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.right),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _subjectName(List<SubjectModel> subjects, String id) {
  try {
    return subjects.firstWhere((s) => s.id == id).name;
  } catch (_) {
    return id;
  }
}

String _gradeTypeName(String type) {
  switch (type) {
    case 'exam': return 'Examen';
    case 'quiz': return 'Interrogation';
    case 'homework': return 'Devoir Maison';
    default: return type;
  }
}

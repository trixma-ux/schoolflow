import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notification_model.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _HomeTab(studentId: user.id, classId: user.classId ?? ''),
      _AcademicTab(studentId: user.id),
      _ScheduleTab(classId: user.classId ?? ''),
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
            builder: (context) => IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(user.profilePic),
              radius: 18,
            ),
          )
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

class _HomeTab extends ConsumerWidget {
  final String studentId;
  final String classId;

  const _HomeTab({required this.studentId, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider(classId));
    final schedulesAsync = ref.watch(classScheduleProvider(classId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Promo Card
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
                  if (schedules.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedules.first.subjectId.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text('${schedules.first.startTime} - ${schedules.first.endTime}', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 16),
                            const Icon(Icons.room, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(schedules.first.room, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const Text('Aucun cours prévu', style: TextStyle(color: Colors.white));
                  }
                },
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Assignments Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Devoirs à rendre', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () {}, child: const Text('Voir tout')),
          ],
        ),
        const SizedBox(height: 8),
        assignmentsAsync.when(
          data: (assignments) {
            if (assignments.isEmpty) return const Text('Aucun devoir prévu.');
            return Column(
              children: assignments.map((assignment) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.assignment, color: AppColors.warning),
                  ),
                  title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Pour le ${DateFormat('dd/MM/yyyy').format(assignment.dueDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ],
    );
  }
}

class _AcademicTab extends ConsumerWidget {
  final String studentId;

  const _AcademicTab({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(studentGradesProvider(studentId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mes Notes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        gradesAsync.when(
          data: (grades) {
             if (grades.isEmpty) return const Text('Aucune note pour le moment.');
             return Column(
               children: grades.map((grade) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(grade.subjectId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${grade.type.name.toUpperCase()} - ${DateFormat('dd/MM/yyyy').format(grade.date)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: grade.score >= 10 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${grade.score}/${grade.maxScore}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: grade.score >= 10 ? AppColors.success : AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )).toList()
             );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ],
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  final String classId;

  const _ScheduleTab({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(classScheduleProvider(classId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mon Emploi du Temps', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        schedulesAsync.when(
          data: (schedules) {
            if(schedules.isEmpty) return const Text("Pas de cours prévu.");
            return Column(
              children: schedules.map((schedule) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(schedule.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(schedule.endTime, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(width: 4, height: 40, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(schedule.subjectId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.room, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(schedule.room, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Erreur: $err'),
        ),
      ],
    );
  }
}

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
            decoration: const BoxDecoration(color: AppColors.primary),
            child: const Row(
              children: [
                Icon(Icons.notifications, color: Colors.white, size: 32),
                SizedBox(width: 16),
                Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: notifsAsync.when(
              data: (notifs) {
                if (notifs.isEmpty) {
                  return const Center(child: Text('Aucune notification.'));
                }
                return ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    final notif = notifs[index];
                    return ListTile(
                      leading: Icon(
                        notif.type == NotificationType.grade ? Icons.grade : Icons.message,
                        color: notif.isRead ? Colors.grey : AppColors.primary,
                      ),
                      title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(notif.message),
                      trailing: Text(DateFormat('dd/MM HH:mm').format(notif.createdAt), style: const TextStyle(fontSize: 10)),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          )
        ],
      ),
    );
  }
}

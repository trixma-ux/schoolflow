import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../shared/profile_screen.dart';
import '../shared/settings_screen.dart';

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
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final classId = user.classId ?? '';
    final unread = ref.watch(unreadNotificationsCountProvider(user.id));

    final pages = [
      _HomeTab(studentId: user.id, classId: classId),
      _AcademicTab(studentId: user.id),
      _ScheduleTab(classId: classId),
      _ClassMembersTab(studentId: user.id, classId: classId),
      _ComplaintsTab(student: user),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Scolarité'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Planning'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Classe'),
          NavigationDestination(icon: Icon(Icons.report_outlined), selectedIcon: Icon(Icons.report), label: 'Plaintes'),
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
        if (classId.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 12),
              Expanded(child: Text('Vous n\'êtes pas encore assigné à une classe. Contactez l\'administration.')),
            ]),
          ),

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
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(subjectName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text('${next.startTime} – ${next.endTime}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 16),
                      const Icon(Icons.room, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(next.room, style: const TextStyle(color: Colors.white70)),
                    ]),
                  ]);
                },
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (e, _) => Text('$e', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text('Devoirs à rendre', style: Theme.of(context).textTheme.titleLarge),
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
                      child: Text(daysLeft <= 0 ? 'Aujourd\'hui' : 'J-$daysLeft',
                        style: TextStyle(color: urgentColor, fontWeight: FontWeight.bold, fontSize: 12)),
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
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.grade_outlined, size: 72, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Aucune note pour le moment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ]));
        }

        double total = 0;
        for (final g in grades) total += (g.score / g.maxScore) * 20;
        final avg = total / grades.length;
        final sorted = [...grades]..sort((a, b) => b.date.compareTo(a.date));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: (avg >= 10 ? AppColors.success : AppColors.error).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (avg >= 10 ? AppColors.success : AppColors.error).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(avg >= 10 ? Icons.trending_up : Icons.trending_down,
                  color: avg >= 10 ? AppColors.success : AppColors.error, size: 40),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Moyenne Générale', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('${avg.toStringAsFixed(2)}/20',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: avg >= 10 ? AppColors.success : AppColors.error)),
                  Text('${grades.length} note(s)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
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
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_outlined, size: 72, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Aucun cours planifié.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('L\'emploi du temps sera ajouté par l\'administration.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ]));
        }

        final byDay = <int, List<dynamic>>{};
        for (final s in schedules) byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
        final sortedDays = byDay.keys.toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mon Emploi du Temps', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final day in sortedDays) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(_dayNames[day], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
              ),
              ...byDay[day]!.map((s) {
                final subjectName = _subjectName(subjects, s.subjectId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Column(children: [
                        Text(s.startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(s.endTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.room, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(s.room, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ])),
                    ]),
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

// ─── Class Members Tab ────────────────────────────────────────────────────────

class _ClassMembersTab extends ConsumerWidget {
  final String studentId;
  final String classId;
  const _ClassMembersTab({required this.studentId, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (classId.isEmpty) {
      return const Center(child: Text('Pas encore assigné à une classe.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final classesAsync = ref.watch(classesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final allClasses = classesAsync.valueOrNull ?? [];
    final allUsers = usersAsync.valueOrNull ?? [];

    final cls = allClasses.where((c) => c.id == classId).firstOrNull;
    if (cls == null) return const Center(child: CircularProgressIndicator());

    final students = allUsers.where((u) => u.role == UserRole.student && cls.studentIds.contains(u.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.class_, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cls.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('${students.length} élève(s)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: students.length,
            itemBuilder: (_, i) {
              final s = students[i];
              final isMe = s.id == studentId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isMe ? AppColors.primary : AppColors.info).withValues(alpha: 0.15),
                  child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                    style: TextStyle(color: isMe ? AppColors.primary : AppColors.info, fontWeight: FontWeight.bold)),
                ),
                title: Row(children: [
                  Text(s.name),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Moi', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Complaints Tab ───────────────────────────────────────────────────────────

class _ComplaintsTab extends ConsumerStatefulWidget {
  final UserModel student;
  const _ComplaintsTab({required this.student});

  @override
  ConsumerState<_ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends ConsumerState<_ComplaintsTab> {
  bool _showForm = false;
  final _descCtrl = TextEditingController();
  String _type = 'grade';
  bool _sending = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    setState(() => _sending = true);
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      if (firestore == null) throw Exception('Firebase non disponible');
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await firestore.collection('complaints').doc(id).set({
        'id': id,
        'studentId': widget.student.id,
        'studentName': widget.student.name,
        'type': _type,
        'description': desc,
        'status': 'pending',
        'adminResponse': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _descCtrl.clear();
      setState(() => _showForm = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plainte envoyée !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(studentComplaintsProvider(widget.student.id));

    return complaintsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (complaints) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: Text('Mes Plaintes', style: Theme.of(context).textTheme.titleLarge)),
            ElevatedButton.icon(
              icon: Icon(_showForm ? Icons.close : Icons.add),
              label: Text(_showForm ? 'Annuler' : 'Nouvelle plainte'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () => setState(() => _showForm = !_showForm),
            ),
          ]),
          const SizedBox(height: 12),

          if (_showForm) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type de plainte', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      ChoiceChip(label: const Text('Note'), selected: _type == 'grade',
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _type = 'grade')),
                      ChoiceChip(label: const Text('Absence'), selected: _type == 'absence',
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _type = 'absence')),
                      ChoiceChip(label: const Text('Autre'), selected: _type == 'other',
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _type = 'other')),
                    ]),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Décrivez votre situation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        onPressed: _sending ? null : _submit,
                        child: _sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Envoyer la plainte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (complaints.isEmpty && !_showForm)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Column(children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                  SizedBox(height: 12),
                  Text('Aucune plainte soumise.', style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            )
          else
            ...complaints.map((c) {
              final statusColor = c.status == 'pending' ? AppColors.warning : c.status == 'resolved' ? AppColors.success : AppColors.error;
              final statusLabel = c.status == 'pending' ? 'En attente' : c.status == 'resolved' ? 'Résolu' : 'Rejeté';
              final typeLabel = c.type == 'grade' ? 'Note' : c.type == 'absence' ? 'Absence' : 'Autre';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
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
                      Text(typeLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(DateFormat('dd/MM/yy').format(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 8),
                    Text(c.description, style: const TextStyle(fontSize: 13)),
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
                          Expanded(child: Text('Réponse admin: ${c.adminResponse}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                        ]),
                      ),
                    ],
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _subjectName(List<SubjectModel> subjects, String id) {
  try { return subjects.firstWhere((s) => s.id == id).name; }
  catch (_) { return id; }
}

String _gradeTypeName(String type) {
  switch (type) {
    case 'exam': return 'Examen';
    case 'quiz': return 'Interrogation';
    case 'homework': return 'Devoir Maison';
    default: return type;
  }
}

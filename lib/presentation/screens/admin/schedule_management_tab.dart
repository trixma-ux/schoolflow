import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class ScheduleManagementTab extends ConsumerStatefulWidget {
  const ScheduleManagementTab({super.key});

  @override
  ConsumerState<ScheduleManagementTab> createState() =>
      _ScheduleManagementTabState();
}

class _ScheduleManagementTabState extends ConsumerState<ScheduleManagementTab> {
  String? _selectedClassId;

  static const _days = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'
  ];

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final classes = classesAsync.valueOrNull ?? [];

    if (_selectedClassId == null && classes.isNotEmpty) {
      _selectedClassId = classes.first.id;
    }

    final schedulesAsync = _selectedClassId != null
        ? ref.watch(classScheduleProvider(_selectedClassId!))
        : const AsyncValue<List<ScheduleModel>>.data([]);
    final usersAsync = ref.watch(allUsersProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final allUsers = usersAsync.valueOrNull ?? [];
    final allSubjects = subjectsAsync.valueOrNull ?? [];
    final teachers = allUsers.where((u) => u.role == UserRole.teacher).toList();

    return Column(
      children: [
        // Class selector
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: classesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erreur: $e'),
            data: (classes) => classes.isEmpty
                ? const Text('Aucune classe — créez-en une d\'abord.',
                    style: TextStyle(color: AppColors.textSecondary))
                : DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'Sélectionner une classe',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.class_,
                          color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text('${c.name} — ${c.academicYear}')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClassId = v),
                  ),
          ),
        ),

        const SizedBox(height: 8),

        // Schedule content
        Expanded(
          child: schedulesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (schedules) {
              if (_selectedClassId == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 72, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('Sélectionnez une classe',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16)),
                    ],
                  ),
                );
              }

              // Group by day
              final byDay = <int, List<ScheduleModel>>{};
              for (final s in schedules) {
                byDay.putIfAbsent(s.dayOfWeek, () => []).add(s);
              }
              for (final list in byDay.values) {
                list.sort((a, b) => a.startTime.compareTo(b.startTime));
              }

              return Stack(
                children: [
                  schedules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_note_outlined,
                                  size: 72,
                                  color: AppColors.textSecondary),
                              const SizedBox(height: 16),
                              const Text(
                                  'Aucun créneau pour cette classe.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter un créneau'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white),
                                onPressed: () => _showAddDialog(
                                    context, teachers, allSubjects,
                                    classes.firstWhere(
                                        (c) => c.id == _selectedClassId!)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: 6,
                          itemBuilder: (ctx, dayIndex) {
                            final dayNum = dayIndex + 1;
                            final slots = byDay[dayNum] ?? [];
                            if (slots.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 16, bottom: 6),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(_days[dayIndex],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 13)),
                                    ),
                                  ]),
                                ),
                                ...slots.map((slot) => _scheduleCard(
                                    context, slot, allUsers, allSubjects,
                                    teachers,
                                    classes.firstWhere(
                                        (c) => c.id == _selectedClassId!))),
                              ],
                            );
                          },
                        ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: 'schedule_fab',
                      onPressed: _selectedClassId == null
                          ? null
                          : () => _showAddDialog(
                              context, teachers, allSubjects,
                              classes.firstWhere(
                                  (c) => c.id == _selectedClassId!)),
                      backgroundColor: AppColors.primary,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Ajouter un créneau',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _scheduleCard(
      BuildContext context,
      ScheduleModel slot,
      List<UserModel> allUsers,
      List<SubjectModel> allSubjects,
      List<UserModel> teachers,
      ClassModel cls) {
    final subject = allSubjects
        .where((s) => s.id == slot.subjectId)
        .firstOrNull;
    final teacher = allUsers
        .where((u) => u.id == slot.teacherId)
        .firstOrNull;

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
      AppColors.accent,
    ];
    final colorIndex = slot.subjectId.hashCode.abs() % colors.length;
    final color = colors[colorIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slot.startTime,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(slot.endTime,
                  style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
        title: Text(
          subject?.name ?? slot.subjectId,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (teacher != null)
              Text('Prof : ${teacher.name}',
                  style: const TextStyle(fontSize: 12)),
            if (slot.room.isNotEmpty)
              Text('Salle : ${slot.room}',
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary)),
          ],
        ),
        isThreeLine: slot.room.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () => _showEditDialog(
                  context, slot, teachers, allSubjects, cls),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () => _deleteSlot(context, slot),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, List<UserModel> teachers,
      List<SubjectModel> subjects, ClassModel cls) {
    _showSlotDialog(context, teachers, subjects, cls, null);
  }

  void _showEditDialog(BuildContext context, ScheduleModel slot,
      List<UserModel> teachers, List<SubjectModel> subjects, ClassModel cls) {
    _showSlotDialog(context, teachers, subjects, cls, slot);
  }

  void _showSlotDialog(
      BuildContext context,
      List<UserModel> teachers,
      List<SubjectModel> subjects,
      ClassModel cls,
      ScheduleModel? existing) {
    int selectedDay = existing?.dayOfWeek ?? 1;
    String startTime = existing?.startTime ?? '08:00';
    String endTime = existing?.endTime ?? '10:00';
    String? selectedSubjectId = existing?.subjectId;
    String? selectedTeacherId = existing?.teacherId;
    String room = existing?.room ?? '';
    bool isSaving = false;

    final roomCtrl = TextEditingController(text: room);

    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
    final timeSlots = [
      '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
      '10:00', '10:30', '11:00', '11:30', '12:00', '12:30',
      '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
      '16:00', '16:30', '17:00', '17:30', '18:00',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(existing == null ? 'Nouveau créneau' : 'Modifier le créneau'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Day
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: const InputDecoration(
                    labelText: 'Jour', border: OutlineInputBorder()),
                items: List.generate(
                    days.length,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text(days[i]))).toList(),
                onChanged: (v) => ss(() => selectedDay = v!),
              ),
              const SizedBox(height: 12),
              // Start / End time
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: startTime,
                    decoration: const InputDecoration(
                        labelText: 'Début', border: OutlineInputBorder()),
                    items: timeSlots
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => ss(() => startTime = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: endTime,
                    decoration: const InputDecoration(
                        labelText: 'Fin', border: OutlineInputBorder()),
                    items: timeSlots
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => ss(() => endTime = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Subject
              DropdownButtonFormField<String>(
                value: selectedSubjectId,
                decoration: const InputDecoration(
                    labelText: 'Matière', border: OutlineInputBorder()),
                items: subjects
                    .map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => ss(() => selectedSubjectId = v),
              ),
              const SizedBox(height: 12),
              // Teacher
              DropdownButtonFormField<String>(
                value: selectedTeacherId,
                decoration: const InputDecoration(
                    labelText: 'Professeur', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ...teachers.map((t) =>
                      DropdownMenuItem(value: t.id, child: Text(t.name))),
                ],
                onChanged: (v) => ss(() => selectedTeacherId = v),
              ),
              const SizedBox(height: 12),
              // Room
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                    labelText: 'Salle (optionnel)',
                    border: OutlineInputBorder()),
                onChanged: (v) => room = v,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: isSaving || selectedSubjectId == null
                  ? null
                  : () async {
                      ss(() => isSaving = true);
                      try {
                        final firestore =
                            ref.read(firebaseFirestoreProvider);
                        if (firestore == null) return;

                        final id = existing?.id ??
                            DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                        final slot = ScheduleModel(
                          id: id,
                          classId: cls.id,
                          subjectId: selectedSubjectId!,
                          teacherId: selectedTeacherId ?? '',
                          room: roomCtrl.text.trim(),
                          dayOfWeek: selectedDay,
                          startTime: startTime,
                          endTime: endTime,
                        );
                        await firestore
                            .collection('schedules')
                            .doc(id)
                            .set(slot.toMap());

                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(existing == null
                                    ? 'Créneau ajouté !'
                                    : 'Créneau modifié !'),
                                backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        ss(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erreur : $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(existing == null ? 'Ajouter' : 'Enregistrer',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSlot(
      BuildContext context, ScheduleModel slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce créneau ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final firestore = ref.read(firebaseFirestoreProvider);
      await firestore?.collection('schedules').doc(slot.id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Créneau supprimé.'),
              backgroundColor: AppColors.success),
        );
      }
    }
  }
}

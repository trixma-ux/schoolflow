import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class ClassDetailDialog extends ConsumerStatefulWidget {
  final ClassModel classModel;
  const ClassDetailDialog({super.key, required this.classModel});

  @override
  ConsumerState<ClassDetailDialog> createState() => _ClassDetailDialogState();
}

class _ClassDetailDialogState extends ConsumerState<ClassDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = ClassRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _removeStudent(String studentId, String studentName) async {
    final ok = await _confirm('Retirer $studentName de la classe ?');
    if (!ok) return;
    try {
      await _repo.removeStudentFromClass(widget.classModel.id, studentId);
      if (mounted) _snack('Élève retiré.', AppColors.success);
    } catch (e) {
      if (mounted) _snack('Erreur : $e', AppColors.error);
    }
  }

  Future<void> _removeTeacher(String teacherId, String teacherName) async {
    final ok = await _confirm('Retirer $teacherName de la classe ?');
    if (!ok) return;
    try {
      await _repo.removeTeacherFromClass(widget.classModel.id, teacherId);
      if (mounted) _snack('Professeur retiré.', AppColors.success);
    } catch (e) {
      if (mounted) _snack('Erreur : $e', AppColors.error);
    }
  }

  Future<void> _addTeacher(List<UserModel> allTeachers) async {
    final already = widget.classModel.teacherIds;
    final available = allTeachers.where((t) => !already.contains(t.id)).toList();
    if (available.isEmpty) {
      _snack('Tous les professeurs sont déjà assignés.', AppColors.warning);
      return;
    }
    String? picked;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('Assigner un professeur'),
          content: DropdownButtonFormField<String>(
            value: picked,
            decoration: const InputDecoration(
              labelText: 'Professeur',
              border: OutlineInputBorder(),
            ),
            items: available
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => ss(() => picked = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: picked == null
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _repo.assignTeacherToClass(
                            widget.classModel.id, picked!);
                        if (mounted) _snack('Professeur assigné !', AppColors.success);
                      } catch (e) {
                        if (mounted) _snack('Erreur : $e', AppColors.error);
                      }
                    },
              child: const Text('Assigner', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent(List<UserModel> allStudents) async {
    final already = widget.classModel.studentIds;
    final available =
        allStudents.where((s) => s.classId == null && !already.contains(s.id)).toList();
    if (available.isEmpty) {
      _snack('Aucun élève disponible sans classe.', AppColors.warning);
      return;
    }
    String? picked;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('Ajouter un élève'),
          content: DropdownButtonFormField<String>(
            value: picked,
            decoration: const InputDecoration(
              labelText: 'Élève',
              border: OutlineInputBorder(),
            ),
            items: available
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => ss(() => picked = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: picked == null
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _repo.addStudentToClass(widget.classModel.id, picked!);
                        if (mounted) _snack('Élève ajouté !', AppColors.success);
                      } catch (e) {
                        if (mounted) _snack('Erreur : $e', AppColors.error);
                      }
                    },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final classesAsync = ref.watch(classesProvider);

    // Get the latest version of this class from the stream
    final currentClass = classesAsync.valueOrNull
            ?.firstWhere((c) => c.id == widget.classModel.id,
                orElse: () => widget.classModel) ??
        widget.classModel;

    final allUsers = usersAsync.valueOrNull ?? [];
    final students =
        allUsers.where((u) => currentClass.studentIds.contains(u.id)).toList();
    final teachers =
        allUsers.where((u) => currentClass.teacherIds.contains(u.id)).toList();
    final allStudents = allUsers.where((u) => u.role == UserRole.student).toList();
    final allTeachers = allUsers.where((u) => u.role == UserRole.teacher).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.class_, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentClass.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(currentClass.academicYear,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                  text:
                      'Élèves (${students.length})'),
              Tab(text: 'Professeurs (${teachers.length})'),
            ],
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
          ),

          // Tab content
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Élèves tab ──
                _MemberList(
                  members: students,
                  emptyIcon: Icons.person_outline,
                  emptyLabel: 'Aucun élève dans cette classe',
                  badgeColor: AppColors.info,
                  onRemove: (u) => _removeStudent(u.id, u.name),
                  onAdd: () => _addStudent(allStudents),
                  addLabel: 'Ajouter un élève',
                ),
                // ── Professeurs tab ──
                _MemberList(
                  members: teachers,
                  emptyIcon: Icons.badge_outlined,
                  emptyLabel: 'Aucun professeur assigné',
                  badgeColor: AppColors.secondary,
                  onRemove: (u) => _removeTeacher(u.id, u.name),
                  onAdd: () => _addTeacher(allTeachers),
                  addLabel: 'Assigner un professeur',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  final List<UserModel> members;
  final IconData emptyIcon;
  final String emptyLabel;
  final Color badgeColor;
  final Future<void> Function(UserModel) onRemove;
  final Future<void> Function() onAdd;
  final String addLabel;

  const _MemberList({
    required this.members,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.badgeColor,
    required this.onRemove,
    required this.onAdd,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(emptyIcon, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(emptyLabel,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: members.length,
                  itemBuilder: (context, i) {
                    final m = members[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: badgeColor.withValues(alpha: 0.15),
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                              color: badgeColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(m.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(m.email,
                          style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.error),
                        tooltip: 'Retirer',
                        onPressed: () => onRemove(m),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(addLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: onAdd,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class AssignClassesDialog extends ConsumerStatefulWidget {
  final UserModel teacher;
  const AssignClassesDialog({super.key, required this.teacher});

  @override
  ConsumerState<AssignClassesDialog> createState() =>
      _AssignClassesDialogState();
}

class _AssignClassesDialogState extends ConsumerState<AssignClassesDialog> {
  final _repo = ClassRepository();
  bool _saving = false;

  Future<void> _assign(String classId, String className) async {
    setState(() => _saving = true);
    try {
      await _repo.assignTeacherToClass(classId, widget.teacher.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${widget.teacher.name} assigné à $className !'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(String classId, String className) async {
    setState(() => _saving = true);
    try {
      await _repo.removeTeacherFromClass(classId, widget.teacher.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${widget.teacher.name} retiré de $className.'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                  child: Text(
                    widget.teacher.name.isNotEmpty
                        ? widget.teacher.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.teacher.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Classes assignées',
                          style: TextStyle(
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
          // Classes list
          SizedBox(
            height: 320,
            child: classesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (classes) {
                if (classes.isEmpty) {
                  return const Center(
                      child: Text('Aucune classe créée.',
                          style:
                              TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: classes.length,
                  itemBuilder: (ctx, i) {
                    final c = classes[i];
                    final isAssigned =
                        c.teacherIds.contains(widget.teacher.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAssigned
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.textSecondary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.class_,
                              color: isAssigned
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              size: 20),
                        ),
                        title: Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(c.academicYear,
                            style: const TextStyle(fontSize: 12)),
                        trailing: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Switch(
                                value: isAssigned,
                                activeColor: AppColors.secondary,
                                onChanged: (val) => val
                                    ? _assign(c.id, c.name)
                                    : _remove(c.id, c.name),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Terminé',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

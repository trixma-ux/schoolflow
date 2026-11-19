import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/class_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'class_detail_dialog.dart';
import '../../../core/data/filieres_ci.dart';
import '../../../core/logic/school_rules.dart';
import '../../../data/models/user_model.dart';

class ClassManagementTab extends ConsumerWidget {
  const ClassManagementTab({super.key});

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2025-2026');
    final capacityCtrl = TextEditingController();
    String? filiere;
    bool autoFill = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle Classe'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom (ex: Terminal S)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(
                  labelText: 'Année scolaire (ex: 2025-2026)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: filiere,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filière',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Aucune (affectation manuelle)')),
                  ...filieresCi.map((f) => DropdownMenuItem<String?>(
                      value: f.id,
                      child: Text('${f.name} — ${f.description}', overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setDialogState(() => filiere = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Effectif maximum (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (filiere != null)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: autoFill,
                  onChanged: (v) => setDialogState(() => autoFill = v ?? true),
                  title: const Text('Y affecter automatiquement les élèves sans classe de cette filière',
                      style: TextStyle(fontSize: 13)),
                ),
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final capText = capacityCtrl.text.trim();
                      final capacity = capText.isEmpty ? null : int.tryParse(capText);
                      if (capText.isNotEmpty && (capacity == null || capacity <= 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Effectif maximum invalide.'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final firestore = ref.read(firebaseFirestoreProvider);
                      var assigned = 0;
                      if (firestore != null) {
                        final id = DateTime.now().millisecondsSinceEpoch.toString();
                        final newClass = ClassModel(
                          id: id,
                          name: nameCtrl.text.trim(),
                          academicYear: yearCtrl.text.trim(),
                          teacherIds: const [],
                          studentIds: const [],
                          filiere: filiere,
                          capacity: capacity,
                        );
                        await firestore
                            .collection('classes')
                            .doc(id)
                            .set(newClass.toMap());
                        if (filiere != null && autoFill) {
                          final users = ref.read(allUsersProvider).valueOrNull ?? <UserModel>[];
                          final classes = ref.read(classesProvider).valueOrNull ?? <ClassModel>[];
                          final candidates = SchoolRules.unassignedStudents(users, classes)
                              .where((u) => u.filiere == filiere)
                              .toList();
                          final plan = SchoolRules.planAutoAssignment(candidates, [newClass]);
                          final repo = ClassRepository();
                          for (final student in plan.keys) {
                            try {
                              await repo.addStudentToClass(id, student.id);
                              assigned++;
                            } catch (_) {}
                          }
                        }
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(assigned > 0
                                  ? 'Classe créée ! $assigned élève(s) affecté(s) automatiquement.'
                                  : 'Classe créée !'),
                              backgroundColor: AppColors.success),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ClassModel c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la classe ?'),
        content: Text(
            'Supprimer "${c.name}" ? Les élèves seront désassignés. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ClassRepository().deleteClass(c.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Classe supprimée.'),
                backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur : $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (classes) {
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.class_outlined,
                    size: 72, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('Aucune classe créée.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une classe'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  onPressed: () => _showAddClassDialog(context, ref),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final c = classes[index];
                final users = usersAsync.valueOrNull ?? [];
                final studentCount =
                    users.where((u) => c.studentIds.contains(u.id)).length;
                final teacherCount = c.teacherIds.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => ClassDetailDialog(classModel: c),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.class_,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                    [
                                      c.academicYear,
                                      if (c.filiere != null) 'Série ${c.filiere}',
                                    ].join(' • '),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _chip(
                                        c.capacity != null
                                            ? '$studentCount/${c.capacity} élève(s)'
                                            : '$studentCount élève(s)',
                                        c.isFull ? AppColors.warning : AppColors.info),
                                    const SizedBox(width: 8),
                                    _chip('$teacherCount prof(s)',
                                        AppColors.secondary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary, size: 20),
                                tooltip: 'Gérer',
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      ClassDetailDialog(classModel: c),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                tooltip: 'Supprimer',
                                onPressed: () =>
                                    _confirmDelete(context, ref, c),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'class_fab',
                onPressed: () => _showAddClassDialog(context, ref),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Nouvelle classe',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

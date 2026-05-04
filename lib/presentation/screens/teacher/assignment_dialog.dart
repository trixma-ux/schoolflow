import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/repositories/academic_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class AssignmentDialog extends ConsumerStatefulWidget {
  const AssignmentDialog({super.key});

  @override
  ConsumerState<AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends ConsumerState<AssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  String? _selectedSubjectId;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une classe et une matière.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final teacher = ref.read(authStateProvider).valueOrNull;
      if (teacher == null) throw Exception('Non authentifié');

      final assignment = AssignmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        teacherId: teacher.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: _dueDate,
      );
      await AcademicRepository().addAssignment(assignment);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devoir publié avec succès !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final teacherClassIds = user?.classIds ?? [];
    final classesAsync = ref.watch(classesProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final allClasses = classesAsync.valueOrNull ?? [];
    final teacherClasses = allClasses.where((c) => teacherClassIds.contains(c.id)).toList();
    final teacherSubjectIds = user?.effectiveSubjectIds ?? [];
    final allSubjects = subjectsAsync.valueOrNull ?? [];
    final teacherSubjects = teacherSubjectIds.isNotEmpty
        ? allSubjects.where((s) => teacherSubjectIds.contains(s.id)).toList()
        : allSubjects;

    return AlertDialog(
      title: const Text('Publier un devoir'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (teacherClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Aucune classe assignée. Configurez votre profil enseignant.', style: TextStyle(color: AppColors.warning)),
                )
              else ...[
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
                  items: teacherClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedClassId = val),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  hint: Text(teacherSubjects.isEmpty ? 'Aucune matière dans votre profil' : 'Choisir une matière'),
                  items: teacherSubjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: teacherSubjects.isEmpty ? null : (val) => setState(() => _selectedSubjectId = val),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre du devoir', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Consignes / Description', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date limite', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_dueDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: (_isLoading || teacherClasses.isEmpty) ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Publier', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

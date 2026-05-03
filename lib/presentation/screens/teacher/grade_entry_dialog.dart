import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/grade_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/academic_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class GradeEntryDialog extends ConsumerStatefulWidget {
  const GradeEntryDialog({super.key});

  @override
  ConsumerState<GradeEntryDialog> createState() => _GradeEntryDialogState();
}

class _GradeEntryDialogState extends ConsumerState<GradeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedSubjectId;
  GradeType _selectedType = GradeType.exam;
  final _scoreController = TextEditingController();
  final _maxScoreController = TextEditingController(text: '20');
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _maxScoreController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedSubjectId == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter tous les champs.'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final teacher = ref.read(authStateProvider).valueOrNull;
      if (teacher == null) throw Exception('Non authentifié');

      final score = double.parse(_scoreController.text.replaceAll(',', '.'));
      final maxScore = double.parse(_maxScoreController.text.replaceAll(',', '.'));

      final grade = GradeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: _selectedStudentId!,
        subjectId: _selectedSubjectId!,
        teacherId: teacher.id,
        score: score,
        maxScore: maxScore,
        type: _selectedType,
        date: DateTime.now(),
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      );
      await AcademicRepository().addGrade(grade);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note enregistrée !'), backgroundColor: AppColors.success),
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
    final usersAsync = ref.watch(allUsersProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    final allClasses = classesAsync.valueOrNull ?? [];
    final teacherClasses = allClasses.where((c) => teacherClassIds.contains(c.id)).toList();
    final allUsers = usersAsync.valueOrNull ?? [];
    final allSubjects = subjectsAsync.valueOrNull ?? [];

    final teacherSubjectIds = user?.effectiveSubjectIds ?? [];
    final teacherSubjects = teacherSubjectIds.isNotEmpty
        ? allSubjects.where((s) => teacherSubjectIds.contains(s.id)).toList()
        : allSubjects;

    if (teacherSubjects.length == 1 && _selectedSubjectId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedSubjectId == null) {
          setState(() => _selectedSubjectId = teacherSubjects.first.id);
        }
      });
    }

    ClassModel? selectedClass;
    try {
      selectedClass = _selectedClassId != null
          ? teacherClasses.firstWhere((c) => c.id == _selectedClassId)
          : null;
    } catch (_) {}

    final studentsInClass = selectedClass != null
        ? allUsers.where((u) => u.role == UserRole.student && selectedClass!.studentIds.contains(u.id)).toList()
        : <UserModel>[];

    return AlertDialog(
      title: const Text('Saisir une note'),
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
                  child: const Text('Aucune classe assignée. Configurez votre profil.', style: TextStyle(color: AppColors.warning)),
                )
              else ...[
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
                  items: teacherClasses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedClassId = val;
                    _selectedStudentId = null;
                  }),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  decoration: const InputDecoration(labelText: 'Élève', border: OutlineInputBorder()),
                  hint: Text(_selectedClassId == null ? 'Sélectionner une classe d\'abord' : 'Choisir un élève'),
                  items: studentsInClass.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: _selectedClassId == null ? null : (val) => setState(() => _selectedStudentId = val),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  items: teacherSubjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GradeType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type d\'évaluation', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: GradeType.exam, child: Text('Examen')),
                    DropdownMenuItem(value: GradeType.quiz, child: Text('Interrogation')),
                    DropdownMenuItem(value: GradeType.homework, child: Text('Devoir Maison')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreController,
                        decoration: const InputDecoration(labelText: 'Note obtenue', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalide';
                          return null;
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('/', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _maxScoreController,
                        decoration: const InputDecoration(labelText: 'Note max', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requis';
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Invalide';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(labelText: 'Appréciation (optionnel)', border: OutlineInputBorder()),
                  maxLines: 2,
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
              : const Text('Enregistrer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

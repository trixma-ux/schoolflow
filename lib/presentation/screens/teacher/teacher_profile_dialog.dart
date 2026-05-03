import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class TeacherProfileDialog extends ConsumerStatefulWidget {
  const TeacherProfileDialog({super.key});

  @override
  ConsumerState<TeacherProfileDialog> createState() => _TeacherProfileDialogState();
}

class _TeacherProfileDialogState extends ConsumerState<TeacherProfileDialog> {
  String? _selectedSubjectId;
  List<String> _selectedClassIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        setState(() {
          _selectedSubjectId = user.subjectId;
          _selectedClassIds = List.from(user.classIds ?? []);
        });
      }
    });
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une matière.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins une classe.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      if (firestore != null) {
        await firestore.collection('users').doc(user.id).update({
          'subjectId': _selectedSubjectId,
          'classIds': _selectedClassIds,
        });
      }

      // Refresh the auth state so the dashboard immediately reflects the new classIds
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !'), backgroundColor: AppColors.success),
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
    final subjectsAsync = ref.watch(subjectsProvider);
    final classesAsync = ref.watch(classesProvider);

    return AlertDialog(
      title: const Text('Mon Profil Enseignant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ma Matière principale', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Aucune matière disponible. Demandez à l\'administrateur d\'initialiser les matières.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('Choisir une matière'),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 20),
            const Text('Mes Classes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Sélectionnez toutes les classes que vous enseignez.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            classesAsync.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Aucune classe créée. Demandez à l\'administrateur de créer des classes.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: classes.map((c) {
                    final isSelected = _selectedClassIds.contains(c.id);
                    return FilterChip(
                      label: Text(c.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClassIds.add(c.id);
                          } else {
                            _selectedClassIds.remove(c.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Erreur: $e'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

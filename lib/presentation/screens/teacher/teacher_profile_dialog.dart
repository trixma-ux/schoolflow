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
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        setState(() {
          _selectedSubjectId = user.subjectId;
          _selectedClassIds = List.from(user.classIds ?? []);
        });
      }
    });
  }

  void _save() async {
    final user = ref.read(authStateProvider).value;
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
      
      // Update local state by forcing a refresh or just returning
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
            const Text('Ma Matière', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            subjectsAsync.when(
              data: (subjects) => DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),
            const Text('Mes Classes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            classesAsync.when(
              data: (classes) => Wrap(
                spacing: 8.0,
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
                    selectedColor: AppColors.primaryLight,
                  );
                }).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
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

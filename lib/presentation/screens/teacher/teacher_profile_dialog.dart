import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/filieres_ci.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class TeacherProfileDialog extends ConsumerStatefulWidget {
  const TeacherProfileDialog({super.key});

  @override
  ConsumerState<TeacherProfileDialog> createState() => _TeacherProfileDialogState();
}

class _TeacherProfileDialogState extends ConsumerState<TeacherProfileDialog> {
  String? _selectedFiliereId;
  List<String> _selectedSubjectIds = [];
  List<String> _selectedClassIds = [];
  bool _isLoading = false;

  static const int _maxClasses = 5;

  FiliereDef? get _selectedFiliere {
    if (_selectedFiliereId == null) return null;
    try {
      return filieresCi.firstWhere((f) => f.id == _selectedFiliereId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        setState(() {
          _selectedFiliereId = user.filiere;
          _selectedSubjectIds = List.from(user.effectiveSubjectIds);
          _selectedClassIds = List.from(user.classIds ?? []);
        });
      }
    });
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    if (_selectedFiliereId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une filière.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedSubjectIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins une matière.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins une classe.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedClassIds.length > _maxClasses) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxClasses classes autorisées.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      if (firestore != null) {
        await firestore.collection('users').doc(user.id).update({
          'filiere': _selectedFiliereId,
          'subjectIds': _selectedSubjectIds,
          'subjectId': _selectedSubjectIds.first,
          'classIds': _selectedClassIds,
        });
      }

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: AppColors.success),
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
    final classesAsync = ref.watch(classesProvider);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_pin, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Profil Enseignant'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Étape 1 — Filière', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFiliereId,
                decoration: const InputDecoration(
                  labelText: 'Choisir une filière',
                  border: OutlineInputBorder(),
                ),
                items: filieresCi.map((f) => DropdownMenuItem(
                  value: f.id,
                  child: Text('${f.name} — ${f.description}', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedFiliereId = val;
                    _selectedSubjectIds = [];
                  });
                },
              ),

              if (_selectedFiliere != null) ...[
                const SizedBox(height: 20),
                const Text('Étape 2 — Matières enseignées', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('Sélectionnez toutes vos matières dans cette filière.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _selectedFiliere!.subjects.map((s) {
                    final isSelected = _selectedSubjectIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.name, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedSubjectIds.add(s.id);
                          } else {
                            _selectedSubjectIds.remove(s.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(color: isSelected ? AppColors.primary : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Étape 3 — Classes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (_selectedClassIds.length > _maxClasses ? AppColors.error : AppColors.info).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedClassIds.length}/$_maxClasses',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedClassIds.length > _maxClasses ? AppColors.error : AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Maximum 5 classes.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Aucune classe créée. Contactez l\'administrateur.', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: classes.map((c) {
                      final isSelected = _selectedClassIds.contains(c.id);
                      final isMaxReached = _selectedClassIds.length >= _maxClasses && !isSelected;
                      return FilterChip(
                        label: Text(c.name, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: isMaxReached ? null : (sel) {
                          setState(() {
                            if (sel) {
                              _selectedClassIds.add(c.id);
                            } else {
                              _selectedClassIds.remove(c.id);
                            }
                          });
                        },
                        selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.secondary,
                        disabledColor: Colors.grey.withValues(alpha: 0.05),
                        labelStyle: TextStyle(
                          color: isMaxReached ? AppColors.textHint : (isSelected ? AppColors.secondary : null),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/filieres_ci.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _email = '';
  String _password = '';
  UserRole _selectedRole = UserRole.student;
  String? _selectedClassId;
  String? _selectedFiliere;
  
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() => _isLoading = true);
      
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final isStudent = _selectedRole == UserRole.student;
        final newUser = await authRepo.register(
          _name,
          _email,
          _password,
          _selectedRole,
          classId: isStudent ? _selectedClassId : null,
          filiere: isStudent ? _selectedFiliere : null,
        );

        String message = 'Utilisateur créé avec succès !';
        if (newUser != null && isStudent) {
          final classRepo = ClassRepository();
          if (_selectedClassId != null) {
            await classRepo.addStudentToClass(_selectedClassId!, newUser.id);
          } else {
            // Affectation automatique selon la filière.
            final cls = await classRepo.autoAssignStudent(newUser);
            message = cls != null
                ? 'Élève créé et affecté automatiquement à ${cls.name}.'
                : 'Élève créé. Aucune classe disponible pour sa filière : il apparaît dans « Élèves sans classe ».';
          }
        }

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.success),
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un utilisateur'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Email invalide' : null,
                onSaved: (val) => _email = val!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mot de passe provisoire', border: OutlineInputBorder()),
                obscureText: true,
                validator: (val) => val == null || val.length < 6 ? 'Min. 6 caractères' : null,
                onSaved: (val) => _password = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle', border: OutlineInputBorder()),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRole = val;
                      if (val != UserRole.student) {
                        _selectedClassId = null;
                      }
                    });
                  }
                },
              ),
              if (_selectedRole == UserRole.student) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFiliere,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Filière', border: OutlineInputBorder()),
                  items: filieresCi
                      .map((f) => DropdownMenuItem(value: f.id, child: Text('${f.name} — ${f.description}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    _selectedFiliere = val;
                    _selectedClassId = null;
                  }),
                  validator: (val) => val == null ? 'Veuillez choisir une filière' : null,
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final classesAsync = ref.watch(classesProvider);
                    return classesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Erreur classes: $e'),
                      data: (classes) {
                        final compatible = classes
                            .where((c) => c.filiere == null || c.filiere == _selectedFiliere)
                            .where((c) => !c.isFull)
                            .toList();
                        return DropdownButtonFormField<String?>(
                          value: _selectedClassId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Automatique (selon la filière)')),
                            ...compatible.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) => setState(() => _selectedClassId = val),
                        );
                      },
                    );
                  },
                ),
              ],
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
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Créer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

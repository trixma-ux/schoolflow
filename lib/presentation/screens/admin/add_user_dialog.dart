import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../core/theme/app_colors.dart';

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
  
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() => _isLoading = true);
      
      try {
        final authRepo = ref.read(authRepositoryProvider);
        final newUser = await authRepo.register(
          _name, 
          _email, 
          _password, 
          _selectedRole, 
          _selectedRole == UserRole.student ? _selectedClassId : null
        );
        
        // Si étudiant et classe sélectionnée, on l'ajoute à la classe
        if (newUser != null && _selectedRole == UserRole.student && _selectedClassId != null) {
           final classRepo = ClassRepository();
           await classRepo.addStudentToClass(_selectedClassId!, newUser.id);
        }
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur créé avec succès !'), backgroundColor: AppColors.success),
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
                initialValue: _selectedRole,
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
                Consumer(
                  builder: (context, ref, child) {
                    final classesAsync = ref.watch(classesProvider);
                    return classesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Erreur classes: $e'),
                      data: (classes) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedClassId,
                          decoration: const InputDecoration(labelText: 'Classe assignée', border: OutlineInputBorder()),
                          items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedClassId = val);
                          },
                          validator: (val) => val == null ? 'Veuillez sélectionner une classe' : null,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class LinkStudentDialog extends ConsumerStatefulWidget {
  final String parentId;
  final String parentName;

  const LinkStudentDialog({
    super.key,
    required this.parentId,
    required this.parentName,
  });

  @override
  ConsumerState<LinkStudentDialog> createState() => _LinkStudentDialogState();
}

class _LinkStudentDialogState extends ConsumerState<LinkStudentDialog> {
  String? _selectedStudentId;
  bool _isLoading = false;

  void _submit() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un élève.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userRepo = UserRepository();
      await userRepo.linkStudentToParent(widget.parentId, _selectedStudentId!);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Élève lié avec succès !'), backgroundColor: AppColors.success),
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
    final usersAsync = ref.watch(allUsersProvider);

    return AlertDialog(
      title: Text('Lier un élève à ${widget.parentName}'),
      content: usersAsync.when(
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Text('Erreur : $err'),
        data: (users) {
          // Filtrer uniquement les étudiants qui ne sont pas encore liés à CE parent
          final students = users.where((u) => 
            u.role == UserRole.student && 
            (u.parentId == null || u.parentId != widget.parentId)
          ).toList();

          if (students.isEmpty) {
            return const Text("Aucun étudiant disponible pour être lié.");
          }

          return DropdownButtonFormField<String>(
            value: _selectedStudentId,
            decoration: const InputDecoration(labelText: 'Sélectionner un élève', border: OutlineInputBorder()),
            items: students.map((s) => DropdownMenuItem(
              value: s.id,
              child: Text(s.name),
            )).toList(),
            onChanged: (val) {
              setState(() => _selectedStudentId = val);
            },
          );
        },
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
              : const Text('Lier', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

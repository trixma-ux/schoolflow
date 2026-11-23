import '../../../core/utils/error_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logic/school_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../providers/data_provider.dart';

/// Liste des élèves nouvellement inscrits sans classe, avec affectation en
/// un clic (classe suggérée selon la filière) ou choix manuel.
class UnassignedStudentsCard extends ConsumerStatefulWidget {
  const UnassignedStudentsCard({super.key, this.repository});

  /// Injectable pour les tests.
  final ClassRepository? repository;

  @override
  ConsumerState<UnassignedStudentsCard> createState() => _UnassignedStudentsCardState();
}

class _UnassignedStudentsCardState extends ConsumerState<UnassignedStudentsCard> {
  final Set<String> _busy = {};
  bool _bulk = false;

  ClassRepository get _repo => widget.repository ?? ClassRepository();

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _assign(UserModel student, ClassModel cls) async {
    setState(() => _busy.add(student.id));
    try {
      await _repo.addStudentToClass(cls.id, student.id);
      _snack('${student.name} affecté(e) à ${cls.name}.', AppColors.success);
    } catch (e) {
      _snack('Erreur : ${errorText(e)}', AppColors.error);
    } finally {
      if (mounted) setState(() => _busy.remove(student.id));
    }
  }

  Future<void> _assignAll(Map<UserModel, ClassModel> plan, int total) async {
    setState(() => _bulk = true);
    var ok = 0;
    for (final e in plan.entries) {
      try {
        await _repo.addStudentToClass(e.value.id, e.key.id);
        ok++;
      } catch (_) {}
    }
    if (mounted) setState(() => _bulk = false);
    final left = total - ok;
    _snack(
      left == 0
          ? '$ok élève(s) affecté(s) automatiquement.'
          : '$ok élève(s) affecté(s). $left sans classe compatible (filière absente ou classes pleines).',
      left == 0 ? AppColors.success : AppColors.warning,
    );
  }

  Future<void> _chooseClass(UserModel student, List<ClassModel> classes) async {
    final available = classes.where((c) => !c.isFull).toList()
      ..sort((a, b) {
        final am = a.filiere == student.filiere ? 0 : 1;
        final bm = b.filiere == student.filiere ? 0 : 1;
        return am != bm ? am.compareTo(bm) : a.name.compareTo(b.name);
      });
    if (available.isEmpty) {
      _snack('Aucune classe disponible. Créez une classe d\'abord.', AppColors.warning);
      return;
    }
    final picked = await showDialog<ClassModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Affecter ${student.name}'),
        children: available
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(c),
                  child: Text([
                    c.name,
                    if (c.filiere != null) 'Série ${c.filiere}',
                    c.capacity != null
                        ? '${c.studentIds.length}/${c.capacity}'
                        : '${c.studentIds.length} élève(s)',
                  ].join(' • ')),
                ))
            .toList(),
      ),
    );
    if (picked != null) await _assign(student, picked);
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <UserModel>[];
    final classes = ref.watch(classesProvider).valueOrNull ?? const <ClassModel>[];
    final unassigned = SchoolRules.unassignedStudents(users, classes);
    final plan = SchoolRules.planAutoAssignment(unassigned, classes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.person_search, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Élèves sans classe (${unassigned.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
            ),
          ]),
          const SizedBox(height: 8),
          if (unassigned.isEmpty)
            const Text('Tous les élèves inscrits sont affectés à une classe.',
                style: TextStyle(fontSize: 12))
          else ...[
            if (plan.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('assign-all'),
                  icon: _bulk
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_mode),
                  label: Text('Affecter automatiquement (${plan.length})'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                  onPressed: _bulk ? null : () => _assignAll(plan, unassigned.length),
                ),
              ),
            const SizedBox(height: 8),
            ...unassigned.map((s) {
              final suggestion = plan[s];
              final busy = _busy.contains(s.id) || _bulk;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.info.withValues(alpha: 0.15),
                  child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
                ),
                title: Text(s.name, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    s.filiere != null ? 'Série ${s.filiere}' : 'Filière non renseignée',
                    suggestion != null ? 'suggestion : ${suggestion.name}' : 'aucune classe compatible',
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: busy
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        if (suggestion != null)
                          IconButton(
                            tooltip: 'Affecter à ${suggestion.name}',
                            icon: const Icon(Icons.check_circle, color: AppColors.success),
                            onPressed: () => _assign(s, suggestion),
                          ),
                        IconButton(
                          tooltip: 'Choisir une classe',
                          icon: const Icon(Icons.playlist_add, color: AppColors.primary),
                          onPressed: () => _chooseClass(s, classes),
                        ),
                      ]),
              );
            }),
          ],
        ],
      ),
    );
  }
}

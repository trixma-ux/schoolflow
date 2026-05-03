import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/filieres_ci.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _saving = true);
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      await firestore?.collection('users').doc(user.id).update({'name': newName});
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nom mis à jour !'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final classes = ref.watch(classesProvider).valueOrNull ?? [];
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            _roleBadge(user.role),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    _infoRow(Icons.person, 'Nom', user.name, trailing: IconButton(
                      icon: Icon(_editing ? Icons.close : Icons.edit, size: 20, color: AppColors.primary),
                      onPressed: () => setState(() {
                        _editing = !_editing;
                        if (!_editing) _nameController.text = user.name;
                      }),
                    )),
                    if (_editing) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Nouveau nom',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saving ? null : _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: _saving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('OK', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    _infoRow(Icons.email_outlined, 'Email', user.email),
                    const Divider(height: 20),
                    _infoRow(Icons.badge_outlined, 'Rôle', _roleName(user.role)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (user.role == UserRole.teacher) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Infos Enseignant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      if (user.filiere != null && user.filiere!.isNotEmpty) ...[
                        _infoRow(Icons.school_outlined, 'Filière', _filiereName(user.filiere!)),
                        const Divider(height: 20),
                      ],
                      if (user.effectiveSubjectIds.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.book_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Matières', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: user.effectiveSubjectIds.map((sid) {
                                      final subj = subjects.where((s) => s.id == sid).firstOrNull;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(subj?.name ?? sid, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                      ],
                      if ((user.classIds ?? []).isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.class_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Classes', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: user.classIds!.map((cid) {
                                      final cls = classes.where((c) => c.id == cid).firstOrNull;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(cls?.name ?? cid, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (user.role == UserRole.student) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Infos Élève', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.class_outlined,
                        'Classe',
                        user.classId != null
                            ? (classes.where((c) => c.id == user.classId).firstOrNull?.name ?? 'Classe inconnue')
                            : 'Non assigné',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (user.role == UserRole.parent) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mes Enfants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      if ((user.studentIds ?? []).isEmpty)
                        const Text('Aucun enfant associé', style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...user.studentIds!.map((sid) {
                          final student = allUsers.where((u) => u.id == sid).firstOrNull;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.info.withValues(alpha: 0.15),
                              child: Text(
                                student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            title: Text(student?.name ?? 'Élève inconnu', style: const TextStyle(fontSize: 14)),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _roleBadge(UserRole role) {
    final Map<UserRole, (Color, String, IconData)> config = {
      UserRole.admin: (AppColors.error, 'Administrateur', Icons.shield),
      UserRole.teacher: (AppColors.secondary, 'Professeur', Icons.person_pin),
      UserRole.student: (AppColors.info, 'Élève', Icons.school),
      UserRole.parent: (AppColors.accent, 'Parent', Icons.family_restroom),
    };
    final (color, label, icon) = config[role]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _roleName(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrateur';
      case UserRole.teacher: return 'Professeur';
      case UserRole.student: return 'Élève';
      case UserRole.parent: return 'Parent';
    }
  }

  String _filiereName(String id) {
    try {
      final f = filieresCi.firstWhere((f) => f.id == id);
      return '${f.name} — ${f.description}';
    } catch (_) {
      return id;
    }
  }
}

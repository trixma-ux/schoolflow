import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/communication_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class MessageDialog extends ConsumerStatefulWidget {
  const MessageDialog({super.key});

  @override
  ConsumerState<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends ConsumerState<MessageDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedReceiverId;
  String _title = '';
  String _message = '';
  NotificationType _selectedType = NotificationType.message;
  
  bool _isLoading = false;

  void _send() async {
    if (_formKey.currentState!.validate() && _selectedReceiverId != null) {
      _formKey.currentState!.save();
      
      final sender = ref.read(authStateProvider).value;
      if (sender == null) return;

      setState(() => _isLoading = true);
      
      try {
        final communicationRepo = CommunicationRepository();
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          receiverId: _selectedReceiverId!,
          senderId: sender.id,
          title: _title,
          message: _message,
          createdAt: DateTime.now(),
          type: _selectedType,
        );
        
        await communicationRepo.sendNotification(notification);

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message envoyé avec succès !'), backgroundColor: AppColors.success),
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
    final usersAsync = ref.watch(allUsersProvider);

    return AlertDialog(
      title: const Text('Envoyer un message'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              usersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Erreur: $e'),
                data: (users) {
                  // Le prof peut écrire aux parents et à l'admin
                  final targets = users.where((u) => u.role == UserRole.parent || u.role == UserRole.admin).toList();
                  
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedReceiverId,
                    decoration: const InputDecoration(labelText: 'Destinataire', border: OutlineInputBorder()),
                    items: targets.map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text('${u.name} (${u.role.name})'),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedReceiverId = val),
                    validator: (val) => val == null ? 'Veuillez choisir un destinataire' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NotificationType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type de message', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: NotificationType.message, child: Text('Message simple')),
                  DropdownMenuItem(value: NotificationType.absence, child: Text('Signalement Absence')),
                  DropdownMenuItem(value: NotificationType.general, child: Text('Requête Administrative')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Sujet', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                onSaved: (val) => _title = val!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
                onSaved: (val) => _message = val!.trim(),
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
          onPressed: _isLoading ? null : _send,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Envoyer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

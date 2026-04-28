import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../../core/theme/app_colors.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Le parent a ses enfants (studentIds)
    final studentIds = user.studentIds ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bonjour, ${user.name.split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Espace Parent', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: studentIds.isEmpty
          ? const Center(child: Text('Aucun enfant associé à ce compte.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: studentIds.length,
              itemBuilder: (context, index) {
                final studentId = studentIds[index];
                return _ChildOverviewCard(studentId: studentId);
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: 'Enfants'),
          NavigationDestination(icon: Icon(Icons.message_outlined), selectedIcon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: 'Paiements'),
        ],
      ),
    );
  }
}

class _ChildOverviewCard extends ConsumerWidget {
  final String studentId;

  const _ChildOverviewCard({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(studentGradesProvider(studentId));
    
    return gradesAsync.when(
      data: (grades) {
        // Calcul de la moyenne (simplifié)
        double totalScore = 0;
        for (var grade in grades) {
          totalScore += (grade.score / grade.maxScore) * 20;
        }
        double average = grades.isEmpty ? 0 : totalScore / grades.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Leo Student (Terminal S)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Actif', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // Aller au détail de l'enfant
                      },
                    )
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Moyenne', '${average.toStringAsFixed(1)}/20', average >= 10 ? AppColors.success : AppColors.error),
                    _buildStat('Absences', '0', AppColors.success),
                    _buildStat('Devoirs', '${grades.length}', AppColors.warning),
                  ],
                )
              ],
            ),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erreur: $err'))),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

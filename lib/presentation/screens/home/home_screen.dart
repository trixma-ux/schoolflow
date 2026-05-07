import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative blobs
          Positioned(top: -120, left: -80,
            child: _blob(320, AppColors.primaryLight.withValues(alpha: 0.18))),
          Positioned(bottom: -100, right: -80,
            child: _blob(380, AppColors.secondary.withValues(alpha: 0.12))),
          Positioned(top: 200, right: -60,
            child: _blob(220, AppColors.accent.withValues(alpha: 0.10))),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── NavBar ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                        const SizedBox(width: 10),
                        const Text('SchoolFlow',
                          style: TextStyle(color: Colors.white, fontSize: 22,
                              fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const Spacer(),
                        _NavBtn(label: 'Se connecter',
                          outlined: true,
                          onTap: () => context.go('/login')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Hero ──────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 28),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Plateforme scolaire ivoirienne',
                            style: TextStyle(color: AppColors.primaryLight, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'La gestion scolaire,\nréinventée.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWide ? 52 : 36,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Un espace numérique unifié pour les admins, professeurs,\nélèves et parents — adapté aux filières CI.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: isWide ? 18 : 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // CTA buttons
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _HeroBtn(
                              label: 'Accéder à mon espace',
                              icon: Icons.login_rounded,
                              primary: true,
                              onTap: () => context.go('/login'),
                            ),
                            _HeroBtn(
                              label: 'Créer un compte',
                              icon: Icons.person_add_rounded,
                              primary: false,
                              onTap: () => context.go('/login?mode=register'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ── Stats bar ─────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: isWide
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _stats(),
                                )
                              : Wrap(
                                  alignment: WrapAlignment.spaceEvenly,
                                  runSpacing: 20,
                                  children: _stats()
                                      .map((w) => SizedBox(width: 140, child: w))
                                      .toList(),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Features ──────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20),
                    child: Column(
                      children: [
                        const Text('Tout ce dont vous avez besoin',
                          style: TextStyle(color: Colors.white, fontSize: 26,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Une plateforme, quatre espaces, zéro friction.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 36),
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _featureCards(),
                              )
                            : Column(children: _featureCards()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Roles section ─────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20),
                    child: Column(
                      children: [
                        const Text('Un espace pour chaque rôle',
                          style: TextStyle(color: Colors.white, fontSize: 26,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        isWide
                            ? Row(children: _roleCards())
                            : Column(
                                children: _roleCards()
                                    .map((w) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: w))
                                    .toList()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ── CTA banner ────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.5),
                                AppColors.primaryLight.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            children: [
                              const Text('Prêt à commencer ?',
                                style: TextStyle(color: Colors.white, fontSize: 28,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              Text(
                                'Connectez-vous à votre espace ou créez un compte\npour rejoindre votre établissement.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.6),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              _HeroBtn(
                                label: 'Accéder à SchoolFlow',
                                icon: Icons.arrow_forward_rounded,
                                primary: true,
                                onTap: () => context.go('/login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Footer ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.school_rounded, color: Colors.white38, size: 18),
                            const SizedBox(width: 8),
                            Text('SchoolFlow • Côte d\'Ivoire',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Plateforme de gestion scolaire numérique',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  List<Widget> _stats() => [
    _Stat(value: '10', label: 'Filières CI'),
    _Stat(value: '4', label: 'Espaces rôles'),
    _Stat(value: '100%', label: 'Cloud & temps réel'),
    _Stat(value: '0', label: 'Installation requise'),
  ];

  List<Widget> _featureCards() => [
    _FeatureCard(icon: Icons.grade_rounded, color: AppColors.primary,
        title: 'Notes & bulletins',
        desc: 'Saisie des notes par matière, calcul de moyennes et suivi par coefficient.'),
    const SizedBox(width: 16, height: 16),
    _FeatureCard(icon: Icons.calendar_month_rounded, color: AppColors.secondary,
        title: 'Emploi du temps',
        desc: 'Consultation des cours, salles et horaires en temps réel.'),
    const SizedBox(width: 16, height: 16),
    _FeatureCard(icon: Icons.report_rounded, color: AppColors.warning,
        title: 'Plaintes & réclamations',
        desc: 'Soumission et suivi des plaintes avec réponse de l\'administration.'),
    const SizedBox(width: 16, height: 16),
    _FeatureCard(icon: Icons.notifications_rounded, color: AppColors.info,
        title: 'Notifications',
        desc: 'Alertes instantanées pour les notes, absences et messages.'),
  ];

  List<Widget> _roleCards() => [
    _RoleCard(icon: Icons.shield_rounded, color: AppColors.error,
        role: 'Admin', desc: 'Gère les utilisateurs, classes, matières et plaintes.'),
    const SizedBox(width: 12, height: 12),
    _RoleCard(icon: Icons.badge_rounded, color: AppColors.secondary,
        role: 'Professeur', desc: 'Saisit les notes, publie devoirs et envoie des messages.'),
    const SizedBox(width: 12, height: 12),
    _RoleCard(icon: Icons.person_rounded, color: AppColors.info,
        role: 'Élève', desc: 'Consulte notes, planning, camarades et soumet des plaintes.'),
    const SizedBox(width: 12, height: 12),
    _RoleCard(icon: Icons.family_restroom_rounded, color: AppColors.accent,
        role: 'Parent', desc: 'Suit la progression de son enfant et reçoit les alertes.'),
  ];
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final String label;
  final bool outlined;
  final VoidCallback onTap;
  const _NavBtn({required this.label, required this.outlined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : AppColors.primary,
          border: outlined ? Border.all(color: Colors.white38) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  const _HeroBtn({required this.label, required this.icon, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withValues(alpha: 0.1),
          border: primary ? null : Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: primary ? AppColors.primary : Colors.white),
            const SizedBox(width: 10),
            Text(label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: primary ? AppColors.primary : Colors.white,
              )),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
          textAlign: TextAlign.center),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _FeatureCard({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 16),
                Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(desc,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String role;
  final String desc;
  const _RoleCard({required this.icon, required this.color, required this.role, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(role,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Text(desc,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

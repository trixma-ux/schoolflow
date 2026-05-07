import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoginMode = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isLoading = true);
    bool success = false;

    if (_isLoginMode) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs.')),
        );
        return;
      }
      success = await ref.read(authStateProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      final nameStr = _nameController.text.trim().toLowerCase().replaceAll(' ', '.');
      if (nameStr.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Un nom valide est requis pour générer l'e-mail.")),
        );
        return;
      }

      bool hasUppercase = _passwordController.text.contains(RegExp(r'[A-Z]'));
      bool hasSpecialCharacters = _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      bool hasMinLength = _passwordController.text.length >= 6;

      if (!hasUppercase || !hasSpecialCharacters || !hasMinLength) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe doit contenir au moins 6 caractères, une majuscule et un symbole.'),
          ),
        );
        return;
      }

      final generatedEmail = '$nameStr@${_selectedRole.name}.com';

      success = await ref.read(authStateProvider.notifier).register(
        _nameController.text.trim(),
        generatedEmail,
        _passwordController.text,
        _selectedRole,
      );

      if (success && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Inscription Réussie !'),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  const TextSpan(text: 'Votre compte a bien été créé.\n\nVoici votre e-mail de connexion généré automatiquement :\n\n'),
                  TextSpan(
                    text: generatedEmail,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                  ),
                  const TextSpan(text: '\n\nVeuillez le conserver précieusement !'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Compris, me connecter'),
              )
            ],
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final errorState = ref.read(authStateProvider).error;
      String errorMessage = _isLoginMode
          ? "Email ou mot de passe incorrect."
          : "Erreur lors de l'inscription. Ce nom est peut-être déjà pris.";
      if (errorState != null) {
        final errStr = errorState.toString();
        if (errStr.contains('user-not-found') || errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
          errorMessage = "Email ou mot de passe incorrect.";
        } else if (errStr.contains('email-already-in-use')) {
          errorMessage = "Ce compte existe déjà.";
        } else if (errStr.contains('network-request-failed')) {
          errorMessage = "Erreur réseau. Vérifiez votre connexion.";
        } else {
          errorMessage = "Erreur : $errStr";
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Navigation is handled automatically by the router's redirect via refreshListenable
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isLoginMode ? 'SchoolFlow' : "S'inscrire",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Bienvenue dans votre espace numérique'
                              : 'Créez votre profil pour commencer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLoginMode
                              ? _buildLoginFields()
                              : _buildRegisterFields(),
                        ),

                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Mot de passe',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: AppColors.primaryDark)
                                : Text(
                                    _isLoginMode ? 'Se connecter' : 'Créer mon compte',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _switchMode,
                          child: Text(
                            _isLoginMode
                                ? "Pas encore de compte ? S'inscrire"
                                : "Déjà un compte ? Se connecter",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Email (ex: leo@student.com)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterFields() {
    return Column(
      key: const ValueKey('register'),
      children: [
        TextField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Prénom et Nom',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UserRole>(
              value: _selectedRole,
              dropdownColor: AppColors.primary,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: const [
                DropdownMenuItem(value: UserRole.student, child: Text('Élève')),
                DropdownMenuItem(value: UserRole.teacher, child: Text('Professeur')),
                DropdownMenuItem(value: UserRole.parent, child: Text('Parent')),
                DropdownMenuItem(value: UserRole.admin, child: Text('Administration')),
              ],
              onChanged: (UserRole? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

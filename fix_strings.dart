import 'dart:io';
void main() {
  final f1 = File('lib/data/repositories/auth_repository_impl.dart');
  var s1 = f1.readAsStringSync();
  s1 = s1.replaceAll(RegExp(r"'Échec de l\\+?'inscription : \$e'"), '"Échec de l\'inscription : \$e"');
  f1.writeAsStringSync(s1);

  final f2 = File('lib/presentation/screens/auth/login_screen.dart');
  var s2 = f2.readAsStringSync();
  s2 = s2.replaceAll(RegExp(r"'S\\+?'inscrire'"), '"S\'inscrire"');
  s2 = s2.replaceAll(RegExp(r"'Erreur lors de l\\+?'inscription\. Ce nom est peut-être déjà pris\.'"), '"Erreur lors de l\'inscription. Ce nom est peut-être déjà pris."');
  f2.writeAsStringSync(s2);
}

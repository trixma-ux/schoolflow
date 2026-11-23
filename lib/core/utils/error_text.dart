/// Texte lisible d'une erreur (sans le préfixe « Exception: »).
String errorText(Object error) =>
    error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

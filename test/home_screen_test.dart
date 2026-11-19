import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_flow/presentation/screens/home/home_screen.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pump();
}

void main() {
  testWidgets('landing page lays out without errors on mobile (390x844) and scrolls to the footer',
      (tester) async {
    await _pumpAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);

    final footer = find.textContaining('Plateforme de gestion scolaire');
    await tester.scrollUntilVisible(footer, 300, scrollable: find.byType(Scrollable).first);
    expect(footer, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landing page lays out without errors on desktop (1280x800)', (tester) async {
    await _pumpAt(tester, const Size(1280, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Un espace pour chaque rôle'), findsOneWidget);
  });

  for (final width in [360.0, 390.0]) {
    testWidgets('logo SchoolFlow non tronqué à ${width.toInt()}px de large', (tester) async {
      await _pumpAt(tester, Size(width, 844));
      expect(tester.takeException(), isNull);
      final logo = find.text('SchoolFlow').first;
      final paragraph = tester.renderObject<RenderParagraph>(logo);
      expect(paragraph.didExceedMaxLines, isFalse);
      // Le texte du logo et le bouton ne se chevauchent pas.
      final logoRect = tester.getRect(logo);
      final btnRect = tester.getRect(find.text('Se connecter'));
      expect(logoRect.right <= btnRect.left, isTrue);
      expect(logoRect.left >= 0 && btnRect.right <= width, isTrue);
    });
  }
}

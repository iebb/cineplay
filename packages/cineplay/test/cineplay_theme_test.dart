import 'package:cineplay/cineplay.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(CineplayThemeData theme, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CineplayTheme(
    data: theme,
    child: Center(child: child),
  ),
);

void main() {
  test('theme data compares by value', () {
    const a = CineplayThemeData(accentColor: Color(0xFF61D6C8));
    const b = CineplayThemeData(accentColor: Color(0xFF61D6C8));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a.copyWith(
        chrome: const FVideoChromeStyle(hoverColor: Color(0x11FFFFFF)),
      ),
      isNot(a),
    );
    expect(
      const FVideoChromeStyle(focusColor: Color(0xFF000001)),
      const FVideoChromeStyle(focusColor: Color(0xFF000001)),
    );
  });

  test('icon controls are circular unless the theme sets a radius', () {
    expect(
      const CineplayThemeData().controlRadiusFor(44),
      BorderRadius.circular(22),
    );
    expect(
      const CineplayThemeData(controlBorderRadius: 8).controlRadiusFor(44),
      BorderRadius.circular(8),
    );
  });

  test('rounded polygons stay inside their vertices', () {
    final path = CineplayGlyphPainter.roundedPolygon(const [
      Offset(31, 17),
      Offset(85, 50),
      Offset(31, 83),
    ], 12);
    expect(path.contains(const Offset(50, 50)), isTrue);
    // Each rounded corner pulls back from its sharp vertex.
    expect(path.contains(const Offset(83, 50)), isFalse);
    expect(path.contains(const Offset(32, 19)), isFalse);
    expect(path.contains(const Offset(32, 81)), isFalse);
  });

  testWidgets('menu items take their colors from the theme', (tester) async {
    const accent = Color(0xFF61D6C8);
    const text = Color(0xFFEEEEEE);
    await tester.pumpWidget(
      _host(
        const CineplayThemeData(accentColor: accent, textColor: text),
        CineplayMenuSurface(
          children: [
            CineplayMenuItem(label: 'Plain', onTap: () {}),
            CineplayMenuItem(label: 'Chosen', selected: true, onTap: () {}),
          ],
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Plain')).style?.color, text);
    expect(tester.widget<Text>(find.text('Chosen')).style?.color, accent);
    // A selected row without a value shows a check glyph.
    expect(
      find.byWidgetPredicate(
        (w) => w is CineplayIcon && w.glyph == CineplayGlyph.check,
      ),
      findsOneWidget,
    );
  });

  testWidgets('glyph builder replaces built-in glyphs', (tester) async {
    final requested = <CineplayGlyph>[];
    await tester.pumpWidget(
      _host(
        CineplayThemeData(
          glyphBuilder: (context, glyph, color, size, shadow) {
            requested.add(glyph);
            return glyph == CineplayGlyph.play
                ? const SizedBox(key: Key('app-play'))
                : null;
          },
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CineplayIcon(CineplayGlyph.play),
            CineplayIcon(CineplayGlyph.pause),
          ],
        ),
      ),
    );

    expect(requested, [CineplayGlyph.play, CineplayGlyph.pause]);
    expect(find.byKey(const Key('app-play')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CineplayIcon),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}

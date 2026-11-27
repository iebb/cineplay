import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'video_player.dart' show FVideoChromeStyle;

/// Glyphs in Cineplay's built-in rounded icon set.
///
/// Every glyph is drawn on a square canvas with rounded corners, round stroke
/// caps, and round joins, so the set reads consistently at 16–40 logical px.
enum CineplayGlyph {
  play,
  pause,
  previous,
  next,
  volume,
  muted,
  pictureInPicture,
  exitPictureInPicture,
  fullscreen,
  exitFullscreen,
  close,
  more,
  hideControls,
  check,
}

/// Builds a replacement for one built-in [CineplayGlyph].
///
/// Return `null` to keep Cineplay's own drawing for that glyph. [shadow] is
/// the drop shadow the player wants behind icons that sit directly on video;
/// it is `null` for icons on opaque surfaces such as menus.
typedef CineplayGlyphBuilder =
    Widget? Function(
      BuildContext context,
      CineplayGlyph glyph,
      Color color,
      double size,
      Shadow? shadow,
    );

/// Shared visual configuration for every Cineplay surface: the player chrome,
/// [CineplaySettingsMenu], [CineplayControlButton], and [CineplayIcon].
///
/// Install it once with [CineplayTheme]; explicit widget arguments such as
/// [FVideoPlayer.chromeStyle] still take precedence.
@immutable
class CineplayThemeData {
  const CineplayThemeData({
    this.chrome = const FVideoChromeStyle(),
    this.accentColor = const Color(0xFFFFFFFF),
    this.videoBackgroundColor = const Color(0xFF000000),
    this.surfaceColor = const Color(0xF0181A20),
    this.surfaceBorderColor = const Color(0x1FFFFFFF),
    this.surfaceRadius = 16,
    this.surfaceShadows = const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    this.surfacePadding = 6,
    this.itemRadius = 10,
    this.itemHeight = 40,
    this.itemHoverColor = const Color(0x14FFFFFF),
    this.itemSelectedColor = const Color(0x1FFFFFFF),
    this.textColor = const Color(0xF2FFFFFF),
    this.secondaryTextColor = const Color(0x99FFFFFF),
    this.dividerColor = const Color(0x14FFFFFF),
    this.fontFamily,
    this.controlBorderRadius,
    this.glyphBuilder,
  }) : assert(surfaceRadius >= 0),
       assert(surfacePadding >= 0),
       assert(itemRadius >= 0),
       assert(itemHeight >= 32),
       assert(controlBorderRadius == null || controlBorderRadius >= 0);

  /// Colors, scrims, shadows, and transport sizes of the player chrome.
  final FVideoChromeStyle chrome;

  /// Timeline progress, selected menu values, and other highlights.
  final Color accentColor;

  /// Letterbox color behind the video frame.
  final Color videoBackgroundColor;

  /// Floating panels such as [CineplaySettingsMenu] and app-owned menus.
  final Color surfaceColor;
  final Color surfaceBorderColor;
  final double surfaceRadius;
  final List<BoxShadow> surfaceShadows;

  /// Inset between a panel edge and its rows.
  final double surfacePadding;

  /// Rows and pills inside floating panels.
  final double itemRadius;
  final double itemHeight;
  final Color itemHoverColor;
  final Color itemSelectedColor;

  /// Text on floating panels.
  final Color textColor;
  final Color secondaryTextColor;
  final Color dividerColor;

  /// Optional font for every Cineplay label; `null` inherits the app font.
  final String? fontFamily;

  /// Hover and focus shape of icon controls. `null` makes them circular.
  final double? controlBorderRadius;

  /// Replaces individual built-in glyphs, for example with an app icon set.
  final CineplayGlyphBuilder? glyphBuilder;

  /// Border radius of the panel's inner rows, matched to [surfaceRadius] so
  /// the inner and outer corners stay concentric.
  double get concentricItemRadius =>
      (surfaceRadius - surfacePadding).clamp(4.0, itemRadius).toDouble();

  /// Hover/focus shape for a square icon control of [size].
  BorderRadius controlRadiusFor(double size) =>
      BorderRadius.circular(controlBorderRadius ?? size / 2);

  /// Panel decoration shared by Cineplay menus and app-owned popovers.
  BoxDecoration get surfaceDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(surfaceRadius),
    border: Border.all(color: surfaceBorderColor),
    boxShadow: surfaceShadows,
  );

  /// Base text style for labels on floating panels.
  TextStyle get labelStyle => TextStyle(
    inherit: false,
    color: textColor,
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    decoration: TextDecoration.none,
  );

  /// Small uppercase section headings on floating panels.
  TextStyle get sectionStyle => labelStyle.copyWith(
    color: secondaryTextColor,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  CineplayThemeData copyWith({
    FVideoChromeStyle? chrome,
    Color? accentColor,
    Color? videoBackgroundColor,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceRadius,
    List<BoxShadow>? surfaceShadows,
    double? surfacePadding,
    double? itemRadius,
    double? itemHeight,
    Color? itemHoverColor,
    Color? itemSelectedColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? dividerColor,
    String? fontFamily,
    double? controlBorderRadius,
    CineplayGlyphBuilder? glyphBuilder,
  }) => CineplayThemeData(
    chrome: chrome ?? this.chrome,
    accentColor: accentColor ?? this.accentColor,
    videoBackgroundColor: videoBackgroundColor ?? this.videoBackgroundColor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    surfaceShadows: surfaceShadows ?? this.surfaceShadows,
    surfacePadding: surfacePadding ?? this.surfacePadding,
    itemRadius: itemRadius ?? this.itemRadius,
    itemHeight: itemHeight ?? this.itemHeight,
    itemHoverColor: itemHoverColor ?? this.itemHoverColor,
    itemSelectedColor: itemSelectedColor ?? this.itemSelectedColor,
    textColor: textColor ?? this.textColor,
    secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
    dividerColor: dividerColor ?? this.dividerColor,
    fontFamily: fontFamily ?? this.fontFamily,
    controlBorderRadius: controlBorderRadius ?? this.controlBorderRadius,
    glyphBuilder: glyphBuilder ?? this.glyphBuilder,
  );

  /// Linearly interpolates colors and dimensions for animated theme changes.
  static CineplayThemeData lerp(
    CineplayThemeData a,
    CineplayThemeData b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final near = t < 0.5 ? a : b;
    return CineplayThemeData(
      chrome: near.chrome,
      accentColor: Color.lerp(a.accentColor, b.accentColor, t)!,
      videoBackgroundColor: Color.lerp(
        a.videoBackgroundColor,
        b.videoBackgroundColor,
        t,
      )!,
      surfaceColor: Color.lerp(a.surfaceColor, b.surfaceColor, t)!,
      surfaceBorderColor: Color.lerp(
        a.surfaceBorderColor,
        b.surfaceBorderColor,
        t,
      )!,
      surfaceRadius: lerpDouble(a.surfaceRadius, b.surfaceRadius, t)!,
      surfaceShadows: BoxShadow.lerpList(
        a.surfaceShadows,
        b.surfaceShadows,
        t,
      )!,
      surfacePadding: lerpDouble(a.surfacePadding, b.surfacePadding, t)!,
      itemRadius: lerpDouble(a.itemRadius, b.itemRadius, t)!,
      itemHeight: lerpDouble(a.itemHeight, b.itemHeight, t)!,
      itemHoverColor: Color.lerp(a.itemHoverColor, b.itemHoverColor, t)!,
      itemSelectedColor: Color.lerp(
        a.itemSelectedColor,
        b.itemSelectedColor,
        t,
      )!,
      textColor: Color.lerp(a.textColor, b.textColor, t)!,
      secondaryTextColor: Color.lerp(
        a.secondaryTextColor,
        b.secondaryTextColor,
        t,
      )!,
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t)!,
      fontFamily: near.fontFamily,
      controlBorderRadius: near.controlBorderRadius,
      glyphBuilder: near.glyphBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CineplayThemeData &&
      other.chrome == chrome &&
      other.accentColor == accentColor &&
      other.videoBackgroundColor == videoBackgroundColor &&
      other.surfaceColor == surfaceColor &&
      other.surfaceBorderColor == surfaceBorderColor &&
      other.surfaceRadius == surfaceRadius &&
      listEquals(other.surfaceShadows, surfaceShadows) &&
      other.surfacePadding == surfacePadding &&
      other.itemRadius == itemRadius &&
      other.itemHeight == itemHeight &&
      other.itemHoverColor == itemHoverColor &&
      other.itemSelectedColor == itemSelectedColor &&
      other.textColor == textColor &&
      other.secondaryTextColor == secondaryTextColor &&
      other.dividerColor == dividerColor &&
      other.fontFamily == fontFamily &&
      other.controlBorderRadius == controlBorderRadius &&
      other.glyphBuilder == glyphBuilder;

  @override
  int get hashCode => Object.hash(
    chrome,
    accentColor,
    videoBackgroundColor,
    surfaceColor,
    surfaceBorderColor,
    surfaceRadius,
    Object.hashAll(surfaceShadows),
    surfacePadding,
    itemRadius,
    itemHeight,
    itemHoverColor,
    itemSelectedColor,
    textColor,
    secondaryTextColor,
    dividerColor,
    fontFamily,
    controlBorderRadius,
    glyphBuilder,
  );
}

/// Provides a [CineplayThemeData] to every Cineplay widget below it.
class CineplayTheme extends InheritedWidget {
  const CineplayTheme({super.key, required this.data, required super.child});

  final CineplayThemeData data;

  static const _fallback = CineplayThemeData();

  /// The nearest theme, or Cineplay's defaults when none is installed.
  static CineplayThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  static CineplayThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CineplayTheme>()?.data;

  @override
  bool updateShouldNotify(CineplayTheme oldWidget) => oldWidget.data != data;
}

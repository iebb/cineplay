import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'cineplay_icon.dart';
import 'cineplay_theme.dart';
import 'video_models.dart';
import 'video_player.dart';

/// A dependency-free, keyboard-accessible interactive surface for Cineplay
/// chrome controls (44x44 minimum hit target, hover wash, and focus ring).
///
/// Unset colors and radius come from the nearest [CineplayTheme].
class CineplayControlButton extends StatefulWidget {
  const CineplayControlButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.toggled = false,
    this.minSize = 44,
    this.borderRadius,
    this.backgroundColor = const Color(0x00000000),
    this.hoverColor,
    this.focusColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool toggled;
  final double minSize;

  /// `null` makes the control circular (or follows
  /// [CineplayThemeData.controlBorderRadius]).
  final double? borderRadius;
  final Color backgroundColor;
  final Color? hoverColor;
  final Color? focusColor;
  final EdgeInsetsGeometry padding;

  @override
  State<CineplayControlButton> createState() => _CineplayControlButtonState();
}

class _CineplayControlButtonState extends State<CineplayControlButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    final enabled = widget.onTap != null;
    final hover = widget.hoverColor ?? theme.chrome.hoverColor;
    final bg = _hovered && enabled
        ? Color.alphaBlend(hover, widget.backgroundColor)
        : widget.backgroundColor;
    final radius = widget.borderRadius == null
        ? theme.controlRadiusFor(widget.minSize)
        : BorderRadius.circular(widget.borderRadius!);
    return Semantics(
      button: true,
      enabled: enabled,
      toggled: widget.toggled,
      label: widget.label,
      child: Focus(
        canRequestFocus: enabled,
        onFocusChange: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        onKeyEvent: (node, event) {
          if (!enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.minSize,
                minHeight: widget.minSize,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radius,
                  border: Border.all(
                    color: _focused
                        ? widget.focusColor ?? theme.chrome.focusColor
                        : const Color(0x00000000),
                    width: 1.5,
                  ),
                ),
                padding: widget.padding,
                child: Center(widthFactor: 1, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A floating panel in the current [CineplayTheme]: surface color, hairline
/// border, layered shadow, and concentric inner padding.
class CineplayMenuSurface extends StatelessWidget {
  const CineplayMenuSurface({
    super.key,
    required this.children,
    this.width = 232,
    this.maxHeight = 360,
  });

  final List<Widget> children;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    return DefaultTextStyle(
      style: theme.labelStyle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: theme.surfaceDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.surfaceRadius),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(theme.surfacePadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of a [CineplayMenuSurface]: optional leading glyph, a label, and an
/// optional trailing value. A selected row without a value shows a check.
class CineplayMenuItem extends StatelessWidget {
  const CineplayMenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.value,
    this.selected = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final CineplayGlyph? icon;
  final String? value;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    final accent = theme.accentColor;
    final value = this.value;
    final labelColor = selected ? accent : theme.textColor;
    return CineplayControlButton(
      label:
          semanticLabel ??
          (value == null || value.isEmpty ? label : '$label, $value'),
      toggled: selected,
      onTap: onTap,
      minSize: theme.itemHeight,
      borderRadius: theme.concentricItemRadius,
      hoverColor: theme.itemHoverColor,
      focusColor: accent,
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 12 : 10),
      child: Row(
        children: [
          if (icon != null) ...[
            CineplayIcon(
              icon!,
              size: 22,
              color: selected ? accent : theme.textColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelStyle.copyWith(
                color: labelColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (value != null && value.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              value,
              style: theme.labelStyle.copyWith(
                color: selected ? accent : theme.secondaryTextColor,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ] else if (selected) ...[
            const SizedBox(width: 12),
            CineplayIcon(CineplayGlyph.check, size: 16, color: accent),
          ],
        ],
      ),
    );
  }
}

/// A small uppercase heading inside a [CineplayMenuSurface].
class CineplayMenuSection extends StatelessWidget {
  const CineplayMenuSection(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Semantics(
        header: true,
        child: Text(title.toUpperCase(), style: theme.sectionStyle),
      ),
    );
  }
}

/// A hairline separator inside a [CineplayMenuSurface].
class CineplayMenuDivider extends StatelessWidget {
  const CineplayMenuDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: SizedBox(
      height: 1,
      child: ColoredBox(color: CineplayTheme.of(context).dividerColor),
    ),
  );
}

/// Ready-to-use, zero-Material/Cupertino settings panel for [FVideoPlayer].
///
/// Exposes one-click playback speed pills, loop toggle, Fit/Fill aspect mode,
/// 90° rotation, chapter jumping, and optional quality/audio/subtitle pickers.
/// Colors, radii, and type come from the nearest [CineplayTheme].
class CineplaySettingsMenu extends StatelessWidget {
  const CineplaySettingsMenu({
    super.key,
    required this.scope,
    this.speeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
    this.qualities = const [],
    this.selectedQualityId,
    this.onSelectQuality,
    this.audioTracks = const [],
    this.selectedAudioTrackId,
    this.onSelectAudioTrack,
    this.subtitleTracks = const [],
    this.selectedSubtitleTrackId,
    this.onSelectSubtitleTrack,
    this.onCaptureFrame,
    this.accentColor,
    this.width = 264,
    this.maxHeight = 360,
  });

  final FVideoChromeScope scope;
  final List<double> speeds;
  final List<FVideoQualityOption> qualities;
  final String? selectedQualityId;
  final ValueChanged<FVideoQualityOption>? onSelectQuality;
  final List<FVideoAudioTrack> audioTracks;
  final int? selectedAudioTrackId;
  final ValueChanged<FVideoAudioTrack>? onSelectAudioTrack;
  final List<FVideoSubtitleTrack> subtitleTracks;
  final int? selectedSubtitleTrackId;
  final ValueChanged<FVideoSubtitleTrack?>? onSelectSubtitleTrack;
  final VoidCallback? onCaptureFrame;

  /// Overrides [CineplayThemeData.accentColor] for this menu only.
  final Color? accentColor;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final inherited = CineplayTheme.of(context);
    final theme = accentColor == null
        ? inherited
        : inherited.copyWith(accentColor: accentColor);
    final snapshot = scope.snapshot;
    final actions = scope.actions;
    final currentSpeed = snapshot.value.playbackSpeed;
    final rotationDegrees = (snapshot.rotationQuarterTurns & 3) * 90;

    return CineplayTheme(
      data: theme,
      child: CineplayMenuSurface(
        width: width,
        maxHeight: maxHeight,
        children: [
          const CineplayMenuSection('Speed'),
          _PillRow(
            children: [
              for (final speed in speeds)
                _Pill(
                  label: _formatSpeed(speed),
                  selected: (currentSpeed - speed).abs() < 0.01,
                  onTap: () => unawaited(actions.setPlaybackSpeed(speed)),
                ),
            ],
          ),
          const CineplayMenuDivider(),
          CineplayMenuItem(
            label: 'Loop',
            value: snapshot.isLooping ? 'On' : 'Off',
            selected: snapshot.isLooping,
            onTap: () => unawaited(actions.toggleLooping()),
          ),
          CineplayMenuItem(
            label: 'Aspect',
            value: snapshot.fit == BoxFit.cover ? 'Fill' : 'Fit',
            selected: snapshot.fit == BoxFit.cover,
            onTap: actions.toggleFit,
          ),
          CineplayMenuItem(
            label: 'Rotate',
            value: '$rotationDegrees°',
            selected: rotationDegrees != 0,
            onTap: actions.rotateClockwise,
          ),
          if (onCaptureFrame != null)
            CineplayMenuItem(
              label: 'Capture Frame',
              value: 'PNG',
              onTap: onCaptureFrame,
            ),
          if (qualities.isNotEmpty && onSelectQuality != null) ...[
            const CineplayMenuDivider(),
            const CineplayMenuSection('Quality'),
            _PillRow(
              children: [
                for (final quality in qualities)
                  _Pill(
                    label: quality.label,
                    selected: quality.id == selectedQualityId,
                    onTap: () => onSelectQuality!(quality),
                  ),
              ],
            ),
          ],
          if (audioTracks.length > 1 && onSelectAudioTrack != null) ...[
            const CineplayMenuDivider(),
            const CineplayMenuSection('Audio'),
            for (final track in audioTracks)
              CineplayMenuItem(
                label: track.label,
                selected: track.id == selectedAudioTrackId,
                onTap: () => onSelectAudioTrack!(track),
              ),
          ],
          if (subtitleTracks.isNotEmpty && onSelectSubtitleTrack != null) ...[
            const CineplayMenuDivider(),
            const CineplayMenuSection('Subtitles'),
            CineplayMenuItem(
              label: 'Off',
              selected: selectedSubtitleTrackId == null,
              onTap: () => onSelectSubtitleTrack!(null),
            ),
            for (final track in subtitleTracks)
              CineplayMenuItem(
                label: track.label,
                selected: track.id == selectedSubtitleTrackId,
                onTap: () => onSelectSubtitleTrack!(track),
              ),
          ],
          if (snapshot.chapters.isNotEmpty) ...[
            const CineplayMenuDivider(),
            const CineplayMenuSection('Chapters'),
            for (final chapter in snapshot.chapters)
              CineplayMenuItem(
                label: chapter.title.isEmpty
                    ? _formatDuration(chapter.position)
                    : chapter.title,
                value: _formatDuration(chapter.position),
                selected: snapshot.currentChapter == chapter,
                onTap: () => unawaited(actions.seekToChapter(chapter)),
              ),
          ],
        ],
      ),
    );
  }

  static String _formatSpeed(double speed) {
    final text = speed.toStringAsFixed(2);
    if (text.endsWith('.00')) return '${text.substring(0, text.length - 3)}×';
    if (text.endsWith('0')) return '${text.substring(0, text.length - 1)}×';
    return '$text×';
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 86400 * 99);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
    child: Wrap(spacing: 6, runSpacing: 6, children: children),
  );
}

/// A stadium-shaped choice chip for short values such as speeds.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = CineplayTheme.of(context);
    final accent = theme.accentColor;
    return CineplayControlButton(
      label: label,
      toggled: selected,
      minSize: 32,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: selected
          ? accent.withValues(alpha: 0.2)
          : theme.itemHoverColor,
      hoverColor: theme.itemHoverColor,
      focusColor: accent,
      onTap: onTap,
      child: Text(
        label,
        style: theme.labelStyle.copyWith(
          color: selected ? accent : theme.textColor,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

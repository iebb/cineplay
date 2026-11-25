import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'video_models.dart';
import 'video_player.dart';

/// A dependency-free, keyboard-accessible interactive surface for Cineplay
/// chrome controls (44x44 minimum hit target, hover wash, and focus ring).
class CineplayControlButton extends StatefulWidget {
  const CineplayControlButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.toggled = false,
    this.minSize = 44,
    this.borderRadius = 10,
    this.backgroundColor = const Color(0x00000000),
    this.hoverColor = const Color(0x26FFFFFF),
    this.focusColor = const Color(0xFFFFFFFF),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;
  final bool toggled;
  final double minSize;
  final double borderRadius;
  final Color backgroundColor;
  final Color hoverColor;
  final Color focusColor;
  final EdgeInsetsGeometry padding;

  @override
  State<CineplayControlButton> createState() => _CineplayControlButtonState();
}

class _CineplayControlButtonState extends State<CineplayControlButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = _hovered && enabled ? widget.hoverColor : widget.backgroundColor;
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: _focused
                      ? Border.all(color: widget.focusColor, width: 1.5)
                      : null,
                ),
                child: Padding(
                  padding: widget.padding,
                  child: Center(widthFactor: 1, child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ready-to-use, zero-Material/Cupertino settings panel for [FVideoPlayer].
///
/// Exposes one-click playback speed pills, loop toggle, Fit/Fill aspect mode,
/// 90° rotation, chapter jumping, and optional quality/audio/subtitle pickers.
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
    this.accentColor = const Color(0xFF38BDF8),
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
  final Color accentColor;
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final snapshot = scope.snapshot;
    final actions = scope.actions;
    final currentSpeed = snapshot.value.playbackSpeed;
    final rotationDegrees = (snapshot.rotationQuarterTurns & 3) * 90;

    return DefaultTextStyle(
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.none,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xEB14161B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('Speed'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final speed in speeds)
                        _pill(
                          label: _formatSpeed(speed),
                          selected: (currentSpeed - speed).abs() < 0.01,
                          onTap: () =>
                              unawaited(actions.setPlaybackSpeed(speed)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _divider(),
                  const SizedBox(height: 6),
                  _actionRow(
                    title: 'Loop',
                    value: snapshot.isLooping ? 'On' : 'Off',
                    highlighted: snapshot.isLooping,
                    onTap: () => unawaited(actions.toggleLooping()),
                  ),
                  _actionRow(
                    title: 'Aspect',
                    value: snapshot.fit == BoxFit.cover ? 'Fill' : 'Fit',
                    highlighted: snapshot.fit == BoxFit.cover,
                    onTap: actions.toggleFit,
                  ),
                  _actionRow(
                    title: 'Rotate',
                    value: '$rotationDegrees°',
                    highlighted: rotationDegrees != 0,
                    onTap: actions.rotateClockwise,
                  ),
                  if (onCaptureFrame != null)
                    _actionRow(
                      title: 'Capture Frame',
                      value: 'PNG',
                      onTap: onCaptureFrame!,
                    ),
                  if (qualities.isNotEmpty && onSelectQuality != null) ...[
                    const SizedBox(height: 6),
                    _divider(),
                    const SizedBox(height: 8),
                    _sectionLabel('Quality'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final quality in qualities)
                          _pill(
                            label: quality.label,
                            selected: quality.id == selectedQualityId,
                            onTap: () => onSelectQuality!(quality),
                          ),
                      ],
                    ),
                  ],
                  if (audioTracks.length > 1 && onSelectAudioTrack != null) ...[
                    const SizedBox(height: 6),
                    _divider(),
                    const SizedBox(height: 8),
                    _sectionLabel('Audio'),
                    const SizedBox(height: 4),
                    for (final track in audioTracks)
                      _actionRow(
                        title: track.label,
                        value: track.id == selectedAudioTrackId ? '✓' : '',
                        highlighted: track.id == selectedAudioTrackId,
                        onTap: () => onSelectAudioTrack!(track),
                      ),
                  ],
                  if (subtitleTracks.isNotEmpty &&
                      onSelectSubtitleTrack != null) ...[
                    const SizedBox(height: 6),
                    _divider(),
                    const SizedBox(height: 8),
                    _sectionLabel('Subtitles'),
                    const SizedBox(height: 4),
                    _actionRow(
                      title: 'Off',
                      value: selectedSubtitleTrackId == null ? '✓' : '',
                      highlighted: selectedSubtitleTrackId == null,
                      onTap: () => onSelectSubtitleTrack!(null),
                    ),
                    for (final track in subtitleTracks)
                      _actionRow(
                        title: track.label,
                        value: track.id == selectedSubtitleTrackId ? '✓' : '',
                        highlighted: track.id == selectedSubtitleTrackId,
                        onTap: () => onSelectSubtitleTrack!(track),
                      ),
                  ],
                  if (snapshot.chapters.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _divider(),
                    const SizedBox(height: 8),
                    _sectionLabel('Chapters'),
                    const SizedBox(height: 4),
                    for (final chapter in snapshot.chapters)
                      _actionRow(
                        title: chapter.title.isEmpty
                            ? _formatDuration(chapter.position)
                            : chapter.title,
                        value: _formatDuration(chapter.position),
                        highlighted: snapshot.currentChapter == chapter,
                        onTap: () => unawaited(actions.seekToChapter(chapter)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0x99FFFFFF),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
  );

  Widget _divider() =>
      const SizedBox(height: 1, child: ColoredBox(color: Color(0x1FFFFFFF)));

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => CineplayControlButton(
    label: label,
    toggled: selected,
    minSize: 32,
    borderRadius: 8,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    backgroundColor: selected
        ? accentColor.withValues(alpha: 0.24)
        : const Color(0x14FFFFFF),
    onTap: onTap,
    child: Text(
      label,
      style: TextStyle(
        color: selected ? accentColor : const Color(0xE6FFFFFF),
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );

  Widget _actionRow({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool highlighted = false,
  }) => CineplayControlButton(
    label: value.isEmpty ? title : '$title $value',
    toggled: highlighted,
    minSize: 36,
    borderRadius: 8,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    onTap: onTap,
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlighted ? accentColor : const Color(0xF2FFFFFF),
              fontSize: 13,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        if (value.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? accentColor : const Color(0x99FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );

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

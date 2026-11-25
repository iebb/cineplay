import 'package:cineplay_fvp/cineplay_fvp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'FvpControllerBridge.formatTrackLabel formats title and language cleanly',
    () {
      expect(
        FvpControllerBridge.formatTrackLabel(
          metadata: const {'title': 'Japanese', 'language': 'jpn'},
          fallbackPrefix: 'Audio',
          displayIndex: 1,
        ),
        'Japanese (jpn)',
      );
      expect(
        FvpControllerBridge.formatTrackLabel(
          metadata: const {'title': 'English Commentary', 'language': 'und'},
          fallbackPrefix: 'Audio',
          displayIndex: 2,
        ),
        'English Commentary',
      );
      expect(
        FvpControllerBridge.formatTrackLabel(
          metadata: const {'language': 'zh'},
          fallbackPrefix: 'Subtitle',
          displayIndex: 1,
        ),
        'Subtitle 1 (zh)',
      );
      expect(
        FvpControllerBridge.formatTrackLabel(
          metadata: const {},
          fallbackPrefix: 'Subtitle',
          displayIndex: 3,
        ),
        'Subtitle 3',
      );
    },
  );
}

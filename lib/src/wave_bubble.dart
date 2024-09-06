import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

class WaveBubble extends StatefulWidget {
  final bool isSender;
  final String path;
  final double? width;
  final Directory appDirectory;

  const WaveBubble({
    super.key,
    required this.appDirectory,
    required this.path,
    this.width,
    this.isSender = false,
  });

  @override
  State<WaveBubble> createState() => _WaveBubbleState();
}

class _WaveBubbleState extends State<WaveBubble> {
  late final PlayerController controller;
  late final StreamSubscription<PlayerState> playerStateSubscription;
  late final StreamSubscription<int> playerDurationSubscription;
  String fileName = '';
  int duration = 0;
  int actualDuration = 0;

  final playerWaveStyle = const PlayerWaveStyle(
    fixedWaveColor: Colors.white54,
    liveWaveColor: Colors.white,
    spacing: 6,
  );

  @override
  void initState() {
    super.initState();
    controller = PlayerController();
    _preparePlayer();
    playerStateSubscription = controller.onPlayerStateChanged.listen((state) {
      setState(() {
        debugPrint("$fileName: $state");
      });
    });
    playerDurationSubscription =
        controller.onCurrentDurationChanged.listen((newDurations) {
      setState(() {
        actualDuration = newDurations;
        debugPrint("$fileName: $newDurations");
      });
    });
  }

  void _preparePlayer() async {
    await controller
        .preparePlayer(
      path: widget.path,
      shouldExtractWaveform: true,
    )
        .then((_) async {
      final maxDuration = await controller.getDuration(DurationType.max);
      setState(() {
        duration = maxDuration;
        fileName = getFileNameFromPath(widget.path);
      });
    });

    await controller
        .extractWaveformData(
          path: widget.path,
          noOfSamples: playerWaveStyle.getSamplesForWidth(widget.width ?? 200),
        )
        .then((waveformData) => debugPrint(waveformData.toString()));
  }

  @override
  void dispose() {
    playerStateSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 4,
          top: 4,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF276bfd)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!controller.playerState.isStopped)
                  IconButton(
                    onPressed: () async {
                      controller.playerState.isPlaying
                          ? await controller.pausePlayer()
                          : await controller.startPlayer(
                              finishMode: FinishMode.pause,
                            );
                    },
                    icon: Icon(
                      controller.playerState.isPlaying
                          ? Icons.stop
                          : Icons.play_arrow,
                    ),
                    color: Colors.white,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                Expanded(
                  child: AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width * .80, 60),
                    playerController: controller,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: playerWaveStyle,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${formatMillisecondsToMinutesSeconds(actualDuration)} / ${formatMillisecondsToMinutesSeconds(duration)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatMillisecondsToMinutesSeconds(int milliseconds) {
  Duration duration = Duration(milliseconds: milliseconds);
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

String getFileNameFromPath(String path) {
  return File(path).path.split('/').last;
}

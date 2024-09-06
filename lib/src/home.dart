import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:grava_audio/src/wave_bubble.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final RecorderController recorderController;
  late final Directory appDirectory;

  final List<String> _fileNames = List<String>.empty(growable: true);
  bool isRecording = false;

  @override
  void initState() {
    _initialiseControllers();
    _getDirectory();
    _loadFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gravador"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
              itemCount: _fileNames.length,
              itemBuilder: (context, index) {
                final item = _fileNames[index];
                return WaveBubble(
                  path: item,
                  isSender: true,
                  appDirectory: appDirectory,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () async {
                    if (isRecording) {
                      _stopRecord();
                    } else {
                      final path = await _getFilePath();
                      await _startRecord(path);
                    }

                    setState(() {});
                  },
                  icon: Icon(isRecording ? Icons.stop : Icons.mic),
                  color: Colors.black,
                  iconSize: 48,
                ),
                AudioWaveforms(
                  enableGesture: true,
                  size: Size(MediaQuery.of(context).size.width * .75, 79),
                  recorderController: recorderController,
                  waveStyle: const WaveStyle(
                    waveColor: Colors.white,
                    extendWaveform: true,
                    showMiddleLine: false,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: const Color(0xFF1E1B26),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  _startRecord(String path) async {
    try {
      recorderController.reset();
      await recorderController.record(path: path);
    } on Exception catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = true;
      });
    }
  }

  _stopRecord() async {
    try {
      recorderController.reset();
      final path = await recorderController.stop(false);
      if (path != null) {
        debugPrint(path);
        debugPrint("Recorded file size: ${File(path).lengthSync()}");
        _fileNames.add(path);
      }
    } on Exception catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = false;
      });
    }
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  Future<void> _loadFiles() async {
    var directoryApp = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = directoryApp.listSync();

    for (var file in files) {
      if (file is File) {
        final extension = getFileExtension(file.path);
        if (extension == '.m4a') {
          setState(() {
            _fileNames.add(file.path);
          });
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
    }
  }

  Future<String> _getFilePath() async {
    final path =
        "${appDirectory.path}/recording${DateTime.now().toIso8601String()}.m4a";
    return path;
  }

  Future<void> _getDirectory() async {
    appDirectory = await getApplicationDocumentsDirectory();
  }
}

String getFileExtension(String fileName) {
  try {
    return ".${fileName.split('.').last}";
  } catch (e) {
    rethrow;
  }
}

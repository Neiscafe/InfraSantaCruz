import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'PostsRepository.dart';

class DisplayVideoScreen extends StatefulWidget {
  final String imagePath;
  final bool readOnly;

  const DisplayVideoScreen({super.key, required this.imagePath, bool? readOnly})
    : readOnly = readOnly ?? false;

  @override
  State<DisplayVideoScreen> createState() => _DisplayVideoScreenState();
}

class _DisplayVideoScreenState extends State<DisplayVideoScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _videoRodando = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.imagePath));
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                SizedBox.expand(child: Container(color: Colors.black)),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        iconSize: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadiusGeometry.circular(12),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: GestureDetector(
                        child: VideoPlayer(_controller),
                        onTap: () {
                          if (!_controller.value.isPlaying) {
                            _controller.play();
                            setState(() {
                              _videoRodando = true;
                            });
                          } else {
                            _controller.pause();
                            setState(() {
                              _videoRodando = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                if (!widget.readOnly)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FilledButton(
                        onPressed: () async {
                          PostsRepository.adicionaMidia(
                            XFile(widget.imagePath),
                          );
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                        ),
                        child: Text("Enviar este vídeo"),
                      ),
                    ),
                  ),
                if (!_videoRodando)
                  Center(child: Icon(Icons.play_arrow, color: Colors.white)),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

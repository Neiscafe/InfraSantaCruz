import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
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
    final isNetwork =
        widget.imagePath.startsWith('http://') ||
        widget.imagePath.startsWith('https://');
    _controller = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(widget.imagePath))
        : VideoPlayerController.file(File(widget.imagePath));
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
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || _controller.value.hasError) {
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Erro ao carregar o vídeo.",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Voltar"),
                        ),
                      ],
                    ),
                  ),
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
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Stack(
              children: [
                SizedBox.expand(child: Container(color: Colors.black)),
                Align(
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: InteractiveViewer(
                        minScale: 1,
                        boundaryMargin: const EdgeInsets.all(100),
                        maxScale: 3,
                        child: GestureDetector(
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
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  ),
                ),
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
                      icon: const Icon(Icons.arrow_back),
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
                          try {
                            final hasAccess = await Gal.hasAccess();
                            if (!hasAccess) {
                              await Gal.requestAccess();
                            }
                            await Gal.putVideo(widget.imagePath);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Vídeo salvo na galeria!"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint("Erro ao salvar vídeo na galeria: $e");
                          }
                          PostsRepository.adicionaMidia(
                            XFile(widget.imagePath),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        ),
                        child: const Text("Enviar este vídeo"),
                      ),
                    ),
                  ),
                if (!_videoRodando)
                  const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
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

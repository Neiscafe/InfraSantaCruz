import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class DisplayVideoScreen extends StatefulWidget {
  final String imagePath;
  const DisplayVideoScreen({super.key, required this.imagePath});

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
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            children: [
              AspectRatio(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () async {
                      final now = DateTime.now().toString();
                      final result = await Supabase.instance.client.storage
                          .from('posts')
                          .upload('teste1/$now', File(widget.imagePath));
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(result)));
                      sleep(Duration(seconds: 2));
                      Navigator.pop(context);
                    },
                    child: Text("Enviar esta foto"),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: Text('Voltar'),
                  ),
                ],
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
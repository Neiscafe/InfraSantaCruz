import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final XFile file;
  final void Function(XFile file) onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.file,
    required this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _videoController;

  @override
  Widget build(BuildContext context) {
    if (_videoController?.value.isInitialized == true) {
      return GestureDetector(
        child: VideoPlayer(_videoController!),
        onTap: () => widget.onTap(widget.file),
      );
    } else {
      return CircularProgressIndicator();
    }
  }

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.file.path));
    _videoController?.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:myapp/PostsRepository.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final bool readOnly;
  final XFile file;

  DisplayPictureScreen({super.key, required this.imagePath, bool? readOnly})
    : file = XFile(imagePath),
      readOnly = readOnly ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
              child: Image.file(File(file.path), fit: BoxFit.fitHeight),
            ),
          ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FilledButton(
                  onPressed: () async {
                    PostsRepository.adicionaMidia(file);
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  ),
                  child: Text("Enviar esta foto"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

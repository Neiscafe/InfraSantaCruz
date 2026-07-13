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
      appBar: AppBar(title: const Text('Ver Foto')),
      body: Stack(
        children: [
          Stack(
            children: [
              Image.file(File(file.path)),
              if (!readOnly)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: FilledButton(
                      onPressed: () async {
                        PostsRepository.adicionaMidia(file);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                      ),
                      child: Text("Enviar esta foto"),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

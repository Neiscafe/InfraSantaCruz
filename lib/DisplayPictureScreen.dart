import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:myapp/PostsRepository.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final XFile file;

  DisplayPictureScreen({super.key, required this.imagePath})
    : file = XFile(imagePath);

  @override
  Widget build(BuildContext context) {
    final children = [
      Image.file(File(file.path)),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            onPressed: () async {
              PostsRepository.adicionaImagem(file);
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
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Stack(children: children),
    );
  }
}

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
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
          InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 1,
            maxScale: 3,
            child: Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(file.path), fit: BoxFit.fitHeight),
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
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      final hasAccess = await Gal.hasAccess();
                      if (!hasAccess) {
                        await Gal.requestAccess();
                      }
                      await Gal.putImage(file.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Imagem salva na galeria!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Erro ao salvar imagem na galeria: $e");
                    }
                    PostsRepository.adicionaMidia(file);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  ),
                  child: const Text("Enviar esta foto"),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

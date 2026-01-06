import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final File file;
  DisplayPictureScreen({super.key, required this.imagePath})
    : file = File(imagePath);

  @override
  Widget build(BuildContext context) {
    final children = [
      Image.file(file),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(
            onPressed: () async {
              final now = DateTime.now().toString();
              final result = await Supabase.instance.client.storage
                  .from('posts')
                  .upload('teste1/$now', File(file.path));
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
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Stack(children: children),
    );
  }
}

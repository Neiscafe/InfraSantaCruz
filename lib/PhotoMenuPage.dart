import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/TirarFotoPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final controller = MyAppController();

class PhotoMenuPage extends StatelessWidget {
  const PhotoMenuPage({super.key});
  void pickSingleFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String path = result.files.single.path!;
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DisplayPictureScreen(imagePath: path);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _future = controller.listaImagens('teste1');
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            final List<Widget> futureChildren;
            if (snapshot.hasData) {
              final data = snapshot.data!;
              final List<Widget> screenImages = [];
              for (final imagem in data) {
                final future = Supabase.instance.client.storage
                    .from('posts')
                    .download('/teste1/' + imagem.name);
                screenImages.add(
                  FutureBuilder(
                    future: future,
                    builder: (context, snapshot) {
                      Widget child;
                      if (snapshot.hasData) {
                        try {
                          child = Image.memory(snapshot.data!);
                        } catch (e) {
                          child = Center(child: Text('Vídeo'));
                        }
                      } else if (snapshot.hasError) {
                        child = Text(snapshot.error.toString() + imagem.name);
                      } else {
                        child = CircularProgressIndicator();
                      }
                      return Card(child: child);
                    },
                  ),
                );
              }
              final size = MediaQuery.of(context).size;
              futureChildren = [
                Container(
                  height: size.width / 2,
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: screenImages,
                  ),
                ),
              ];
            } else if (snapshot.hasError) {
              futureChildren = [
                Text("Ocorreu um erro:"),
                Text(snapshot.error.toString()),
              ];
            } else {
              futureChildren = [
                Text("Carregando..."),
                CircularProgressIndicator(),
              ];
            }
            return Column(
              children: futureChildren,
              mainAxisSize: MainAxisSize.max,
            );
          },
        ),
        FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TirarFotoPage()),
            );
          },
          child: Text("Tirar foto"),
        ),
        TextButton(onPressed: () {}, child: Text("Anexar")),
      ],
    );
  }
}

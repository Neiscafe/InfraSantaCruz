import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/MyAppController.dart';
import 'package:myapp/PhotoMenuPage.dart';
import 'package:myapp/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final controller = MyAppController();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final _future = controller.listaPosts();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(""),
      ),
      body: FutureBuilder(
        future: _future,
        builder: ((context, snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final text = data.toString();
            children = [
              Text("Sucesso!"),
              Text(text, style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1.0))),
            ];
          } else if (snapshot.hasError) {
            final erro = snapshot.error!.toString();
            children = [Text("Ocorreu um erro:"), Text(erro)];
          } else {
            children = [Text("Carregando..."), CircularProgressIndicator()];
          }
          children.add(
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PhotoMenuPage()),
                );
              },
              child: Text("Ir para fotos"),
            ),
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: children,
            ),
          );
        }),
      ),
    );
  }
}

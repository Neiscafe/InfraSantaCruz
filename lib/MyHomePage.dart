import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

// Modelo simplificado de Post
class Post {
  final String id;
  final String title;
  final String location;
  Post({required this.id, required this.title, required this.location});
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}


class PaginatedHomeScreen extends StatefulWidget {
  @override
  _PaginatedHomeScreenState createState() => _PaginatedHomeScreenState();
}

class _PaginatedHomeScreenState extends State<PaginatedHomeScreen> {
  static const _pageSize = 10;

  // O controlador gerencia o estado da paginação
  late final _pagingController = PagingController<int, Post>(
    getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => RemoteApi.getPhotos(pageKey),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feed Paginado"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _pagingController.refresh(),
          )
        ],
      ),
      // PagedListView é o Widget que faz a mágica acontecer
      body: PagedListView<int, Post>(
        builderDelegate: PagedChildBuilderDelegate<Post>(
          itemBuilder: (context, item, index) => PostCard(post: item),
          // Customização dos estados (opcional)
          firstPageProgressIndicatorBuilder: (_) => Center(child: CircularProgressIndicator()),
          newPageProgressIndicatorBuilder: (_) => Center(child: LinearProgressIndicator()),
          noItemsFoundIndicatorBuilder: (_) => Center(child: Text("Nenhum post encontrado")),
        ), state: _pagingController!.value, fetchNextPage: () {  },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:myapp/MyAppController.dart';
// import 'package:myapp/PhotoMenuPage.dart';
// import 'package:myapp/main.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// final controller = MyAppController();
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   @override
//   Widget build(BuildContext context) {
//     final _future = controller.listaPosts();
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(""),
//       ),
//       body: FutureBuilder(
//         future: _future,
//         builder: ((context, snapshot) {
//           List<Widget> children;
//           if (snapshot.hasData) {
//             final data = snapshot.data!;
//             final text = data.toString();
//             children = [
//               Text("Sucesso!"),
//               Text(text, style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1.0))),
//             ];
//           } else if (snapshot.hasError) {
//             final erro = snapshot.error!.toString();
//             children = [Text("Ocorreu um erro:"), Text(erro)];
//           } else {
//             children = [Text("Carregando..."), CircularProgressIndicator()];
//           }
//           children.add(
//             FilledButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => PhotoMenuPage()),
//                 );
//               },
//               child: Text("Ir para fotos"),
//             ),
//           );
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.max,
//               children: children,
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

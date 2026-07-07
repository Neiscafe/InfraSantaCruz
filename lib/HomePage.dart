import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:myapp/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'MyAppController.dart';
import 'Post.dart';


final controller = MyAppController();

// --- Página Principal ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Armazenamos o Future em uma variável para evitar que ele seja
  // disparado novamente em cada rebuild do widget.
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = controller.buscaPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed de Posts'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          // 1. Enquanto carrega
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Se houver erro
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar posts: ${snapshot.error}'));
          }

          // 3. Se a lista estiver vazia
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum post encontrado.'));
          }

          // 4. Sucesso: Exibe a lista
          final posts = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          );
        },
      ),
    );
  }

  // Widget de Card customizado
  Widget _buildPostCard(Post post) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.pin_drop, color: Colors.white),
        ),
        title: Text(
          post.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  post.location,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          // Ação ao clicar no card
          print("Clicou no post: ${post.id}");
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Post.dart';

class PostsRepository {
  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseStorageClient get storage => client.storage;

  static GoTrueClient get auth => client.auth;

  static Future<List<FileObject>> buscaFotos(String postId) async {
    return storage.from('posts').list(path: postId);
  }

  // static final StreamController<List<XFile>> _ongoingPostImages =
  //     StreamController();

  // static Stream<List<XFile>> get ongoingPostImages => _ongoingPostImages.stream;
  static List<XFile> ongoingPostImages = [];

  static void adicionaImagem(XFile imagem) async {
    // final currentList = (await _ongoingPostImages.stream.toList()).last;
    // currentList.add(imagem);
    // _ongoingPostImages.add(currentList);
    ongoingPostImages.add(imagem);
  }

  static void removeImagem(XFile imagem) async {
    // final currentList = (await _ongoingPostImages.stream.toList()).last;
    ongoingPostImages.remove(imagem);
    // _ongoingPostImages.add(currentList);
  }

  static Future<List<Post>> buscaPosts() async {
    final response = await client.from('posts').select();
    return response.map((item) => Post.fromMap(item)).toList();
  }

  static Future<bool> criaPost(Post post) async {
    return await client.from("posts").insert(post.toMap());
  }
}

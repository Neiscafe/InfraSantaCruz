import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Post.dart';

sealed class OrdemPosts {}

sealed class LonLat extends OrdemPosts {
  final double lon;
  final double lat;

  LonLat(this.lon, this.lat);
}

sealed class Likes extends OrdemPosts {}

sealed class DataCriacao extends OrdemPosts {}

sealed class FiltroPosts {}

class Endereco extends FiltroPosts {
  final TipoEndereco tipoFiltro;
  final String valorFiltro;

  Endereco(this.tipoFiltro, this.valorFiltro);
}

enum TipoEndereco { rua, bairro }

class PostsRepository {
  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseStorageClient get storage => client.storage;

  static GoTrueClient get auth => client.auth;

  static String get userId => AuthRepository.session!.user.id;

  // static Future<List<String>> buscaUrlsDownloadMidia(String postId) async {
  //   try {
  //     final medias = await storage.from('posts').list(path: "$userId/$postId");
  //     final mediaUrls = medias
  //         .map((media) => "$userId/$postId/${media.name}")
  //         .toList();
  //     final signedUrls = await storage.from('posts').createSignedUrls(
  //         mediaUrls, 60);
  //     signedUrls.map((signedUrl) => signedUrl.);
  //   } catch (e) {
  //     debugPrint("$e");
  //     throw Exception("Não foi possível listar as mídias: $e");
  //   }
  // }

  static List<XFile> midiasPost = [];

  static void adicionaMidia(XFile midia) async {
    midiasPost.add(midia);
  }

  static void removeImagem(XFile imagem) async {
    midiasPost.remove(imagem);
  }

  static Future<List<Post>> buscaPosts(int currentPage) async {
    try {
      final response = await client.from('posts').select(
        '''*, total_curtidas, curtido_por_mim''',
      );
      //.neq("usuario_id", AuthRepository.session!.user.id);
      return response.map((item) => Post.fromMap(item)).toList();
    } on Exception catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar posts: $e");
    }
  }

  static Future<void> criaPost(Post post) async {
    List<Map<String, dynamic>> filesData = List.empty();
    for (int i = 0; i < post.jsonMidias.length; i++) {
      final arquivo = midiasPost[i];
      final privateUrl = "${post.usuarioId}/${post.id}/${arquivo.name}";
      filesData.add({
        "privateUrl": privateUrl,
        "publicUrl": storage.from("posts").getPublicUrl(privateUrl),
        "file": arquivo,
      });
    }
    try {
      await client
          .from("posts")
          .insert(
            post
                .copy(
                  jsonMidias: filesData.map((fileData) {
                    return PostMidia(
                      publicUrl: fileData['publicUrl'],
                      mime: lookupMimeType(fileData['file'].path)!,
                    );
                  }).toList(),
                )
                .toMap(),
          );
    } on Exception catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao criar registro de post: $e");
    }
    try {
      final futureUploads = filesData.map((fileData) async {
        storage
            .from("posts")
            .upload(
              fileData['privateUrl'],
              File.fromUri(Uri.file(fileData['file'].path)),
            );
      });
      await Future.wait(futureUploads);
    } on Exception catch (e, trace) {
      final List<Future<dynamic>> futures = [];
      if (filesData.isNotEmpty) {
        futures.add(storage.from("posts").remove([post.id]));
      }
      futures.add(client.from('posts').delete().eq('post_id', post.id));
      Future.wait(futures);
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao criar mídias do post: $e");
    }
  }

  static void deletaMidia(XFile file) {
    midiasPost.remove(file);
  }

  static Future<void> curtePost(Post post) async {
    try {
      await client.from("post_likes").insert({"post_id": post.id});
    } on Exception catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao curtir post: $e");
    }
  }

  static Future<void> descurtePost(Post post) async {
    try {
      await client
          .from("post_likes")
          .delete()
          .eq("post_id", post.id)
          .eq("usuario_id", userId);
    } on Exception catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao descurtir post: $e");
    }
  }

  static Future<Uint8List> downloadMidia(PostMidia midia) async {
    try {
      return await storage.from("posts").download(midia.publicUrl);
    } on Exception catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao baixar mídia: $e");
    }
  }
}

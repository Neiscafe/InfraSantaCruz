import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart' hide ImageFormat;
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/Comentario.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/v4.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
  static final StreamController<Post> _postUpdatedController =
      StreamController<Post>.broadcast();

  static Stream<Post> get onPostUpdated => _postUpdatedController.stream;

  static void notifyPostUpdated(Post post) {
    _postUpdatedController.add(post);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseStorageClient get storage => client.storage;

  static GoTrueClient get auth => client.auth;

  static String get userId => AuthRepository.session!.user.id;

  static List<XFile> midiasPost = [];

  static void adicionaMidia(XFile midia) async {
    midiasPost.add(midia);
  }

  static void removeImagem(XFile imagem) async {
    midiasPost.remove(imagem);
  }

  static Future<List<Post>> buscaPosts(
    String? dataPostMaisAntigo,
    String? usuarioId,
  ) async {
    try {
      var query = client.from('posts').select(
        '''*, total_curtidas, curtido_por_mim, total_comentarios, usuario:users(*)''',
      );
      if (dataPostMaisAntigo != null) {
        query = query.lt("created_at", dataPostMaisAntigo);
      }
      if (usuarioId != null) {
        query = query.eq("usuario_id", usuarioId);
      } else {
        // query.neq("usuario_id", AuthRepository.usuarioAtual.usuarioId);
      }
      final response = await query
          .order("created_at", ascending: false)
          .order("post_id", ascending: false)
          .limit(20);
      return response.map((item) => Post.fromJson(item)).toList();
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar posts: $e");
    }
  }

  static Future<void> criaPost(Post post) async {
    List<Map<String, dynamic>> filesData = List.empty(growable: true);
    for (int i = 0; i < midiasPost.length; i++) {
      final arquivo = midiasPost[i];
      final privateUrl =
          "${post.usuario.usuarioId}/${post.id}/${UuidV4().generate()}";
      filesData.add({
        "privateUrl": privateUrl,
        "publicUrl": storage.from("posts").getPublicUrl(privateUrl),
        "file": arquivo,
        "mime": lookupMimeType(arquivo.path),
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
                      mime: fileData['mime'],
                    );
                  }).toList(),
                )
                .toJson(),
          );
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      midiasPost.clear();
      throw Exception("Falha ao criar registro de post: $e");
    }
    try {
      int count = 0;
      while (count < filesData.length) {
        final fileData = filesData[count];
        await storage
            .from("posts")
            .upload(
              fileData['privateUrl'],
              File.fromUri(Uri.file(fileData['file'].path)),
              fileOptions: FileOptions(contentType: fileData['mime']),
            );
        count++;
      }
    } catch (e, trace) {
      if (filesData.isNotEmpty) {
        await storage.from("posts").remove([post.id]);
      }
      await client.from('posts').delete().eq('post_id', post.id);
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao criar mídias do post: $e");
    } finally {
      midiasPost.clear();
    }
  }

  static void deletaMidia(XFile file) {
    midiasPost.remove(file);
  }

  static Future<void> curtePost(Post post) async {
    try {
      await client.from("post_likes").insert({"post_id": post.id});
    } catch (e, trace) {
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
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao descurtir post: $e");
    }
  }

  static final Map<String, Future<File>> _thumbFutures = {};
  static final Map<String, File> _thumbFiles = {};

  static File? thumbnailEmCache(PostMidia midia) =>
      _thumbFiles[midia.publicUrl];

  static Future<File> thumbnailVideo(PostMidia midia) {
    return _thumbFutures.putIfAbsent(midia.publicUrl, () {
      final future = _gerarThumbnail(midia).then((f) {
        _thumbFiles[midia.publicUrl] = f;
        return f;
      });
      future.then(
        (_) {},
        onError: (_) => _thumbFutures.remove(midia.publicUrl),
      );
      return future;
    });
  }

  static Future<File> _gerarThumbnail(PostMidia midia) async {
    const baseUrl =
        "https://yombhmzdpmffekqhdtrv.supabase.co/storage/v1/object/public/posts/";
    final remotePath = midia.publicUrl.replaceAll(baseUrl, "");
    final splitPath = remotePath.split("/");
    final postId = splitPath[splitPath.length - 2];
    final fileName = splitPath.last;
    final appDirPath = (await getApplicationCacheDirectory()).path;
    final thumb = File("$appDirPath/$postId/$fileName.thumb.jpg");

    if (await thumb.exists() && await thumb.length() > 0) return thumb;

    final videoCache = File("$appDirPath/$postId/$fileName.mp4");
    final origem = await videoCache.exists() && await videoCache.length() > 0
        ? videoCache.path
        : midia.publicUrl;

    final bytes = await VideoThumbnail.thumbnailData(
      video: origem,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 400,
      quality: 75,
    );
    if (bytes == null || bytes.isEmpty) {
      throw Exception("Falha ao gerar miniatura");
    }
    await thumb.create(recursive: true);
    await thumb.writeAsBytes(bytes);
    return thumb;
  }

  static final Map<String, Future<File>> _videoFutures = {};

  static Future<File> downloadVideo(PostMidia midia) async {
    return _videoFutures.putIfAbsent(midia.publicUrl, () {
      final future = _downloadVideo(midia);
      future.then(
        (_) {},
        onError: (_) => _videoFutures.remove(midia.publicUrl),
      );
      return future;
    });
  }

  static Future<File> _downloadVideo(PostMidia midia) async {
    try {
      final baseUrl =
          "https://yombhmzdpmffekqhdtrv.supabase.co/storage/v1/object/public/posts/";
      final remotePath = midia.publicUrl.replaceAll(baseUrl, "");
      final appDirPath = (await getApplicationCacheDirectory()).path;
      final splitPath = remotePath.split("/");
      final postId = splitPath[splitPath.length - 2];
      final fileName = splitPath.last;
      final cachePath = "$appDirPath/$postId/$fileName.mp4";
      final file = File(cachePath);
      if (await file.exists()) {
        final lastModified = await file.lastModified();
        final modificationDiff = DateTime.now().difference(lastModified);
        final newerThan7Days = modificationDiff < Duration(days: 7);
        if (newerThan7Days) return file;
      } else {
        await file.create(recursive: true);
      }
      final fileBytes = await storage.from("posts").download(remotePath);
      await file.writeAsBytes(fileBytes);
      return file;
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      debugPrint(jsonEncode(midia.toMap()));
      throw Exception("Falha ao baixar mídia: $e");
    }
  }

  static Future<List<Comentario>> buscaRespostas(
    Comentario comentario,
    String? dataComentarioMaisAntigo,
  ) async {
    try {
      var query = client.from('post_comments').select('''*, 
        total_curtidas_comentario,
        total_comentarios_comentario, 
        curtido_por_mim,
        usuario:users!post_comments_usuario_id_fkey(*), 
        reply_username:users!post_comments_user_reply_id_fkey(full_name)
        ''');

      if (dataComentarioMaisAntigo != null) {
        query = query.lt("created_at", dataComentarioMaisAntigo);
      }
      var response = await query
          .eq("comment_above_id", comentario.commentId)
          .order("created_at", ascending: false)
          .order("comment_id", ascending: false)
          .limit(20);
      return response.map((item) => Comentario.fromJson(item)).toList();
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar comentários: $e");
    }
  }

  static Future<void> curteComentario(Comentario comentario) async {
    try {
      await client.from('comment_likes').insert({
        "id": UuidV4().generate(),
        "created_at": DateTime.now().toString(),
        "comment_id": comentario.commentId,
      });
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar comentários: $e");
    }
  }

  static Future<Comentario> criaComentario(Comentario comentario) async {
    try {
      final response = await client
          .from("post_comments")
          .insert(comentario.toJson())
          .select("*, usuario:users!post_comments_usuario_id_fkey(*)");
      return response.map((it) => Comentario.fromJson(it)).first;
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao criar registro de comentário: $e");
    }
  }

  static Future<void> descurteComentario(Comentario comentario) async {
    try {
      await client
          .from('comment_likes')
          .delete()
          .eq("comment_id", comentario.commentId)
          .eq("usuario_id", AuthRepository.session!.user.id);
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar comentários: $e");
    }
  }

  static Future<List<Comentario>> buscaComentarios(
    Post post,
    String? dataComentarioMaisAntigo,
  ) async {
    try {
      var query = client
          .from('post_comments')
          .select('''*, 
            total_curtidas_comentario, 
            total_comentarios_comentario, 
            curtido_por_mim, 
            usuario:users!post_comments_usuario_id_fkey(*)
            ''')
          .eq("post_id", post.id);
      if (dataComentarioMaisAntigo != null) {
        query = query.lt("created_at", dataComentarioMaisAntigo);
      }
      final response = await query
          .isFilter("comment_above_id", null)
          .order("created_at", ascending: false)
          .order("comment_id", ascending: false)
          .limit(20);
      return response.map((item) => Comentario.fromJson(item)).toList();
    } catch (e, trace) {
      debugPrint(trace.toString());
      debugPrint(e.toString());
      throw Exception("Falha ao buscar comentários: $e");
    }
  }
}

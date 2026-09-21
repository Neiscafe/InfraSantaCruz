import 'package:uuid/v4.dart';

import 'Usuario.dart';

class Comentario {
  final String text;
  final String commentId;
  final String createdAt;
  final String postId;
  final String? commentAboveId;
  final String? commentReplyId;
  final String? userReplyId;
  final String? replyUsername;
  final int curtidas;
  final int comentariosAbaixo;
  final Usuario usuario;
  final bool curtidoPorMim;
  final List<Comentario> respostas;
  late DateTime createdDateTime = DateTime.parse(createdAt);

  Comentario copy({
    String? text,
    String? commentId,
    String? createdAt,
    String? postId,
    int? comentariosAbaixo,
    String? commentAboveId,
    int? curtidas,
    bool? curtidoPorMim,
    Usuario? usuario,
    List<Comentario>? respostas,
    String? commentReplyId,
    String? replyUsername,
    String? userReplyId,
  }) {
    return Comentario(
      text: text ?? this.text,
      commentId: commentId ?? this.commentId,
      createdAt: createdAt ?? this.createdAt,
      postId: postId ?? this.postId,
      comentariosAbaixo: comentariosAbaixo ?? this.comentariosAbaixo,
      commentAboveId: commentAboveId ?? this.commentAboveId,
      curtidas: curtidas ?? this.curtidas,
      curtidoPorMim: curtidoPorMim ?? this.curtidoPorMim,
      usuario: usuario ?? this.usuario,
      respostas: respostas ?? this.respostas,
      commentReplyId: commentReplyId ?? this.commentReplyId,
      replyUsername: replyUsername ?? this.replyUsername,
      userReplyId: userReplyId ?? this.userReplyId,
    );
  }

  Comentario({
    required this.text,
    String? commentId,
    String? createdAt,
    required this.postId,
    required this.usuario,
    this.commentAboveId,
    this.curtidas = 0,
    this.comentariosAbaixo = 0,
    this.curtidoPorMim = false,
    List<Comentario>? respostas,
    this.commentReplyId,
    this.userReplyId,
    this.replyUsername,
  }) : this.respostas = respostas ?? List.empty(),
       this.commentId = commentId ?? UuidV4().generate(),
       this.createdAt = createdAt ?? DateTime.now().toString();

  Map<String, dynamic> toJson() {
    return {
      "text": this.text,
      "comment_id": this.commentId,
      "post_id": this.postId,
      "comment_above_id": this.commentAboveId,
      "comment_reply_id": this.commentReplyId,
      "user_reply_id": this.userReplyId,
    };
  }

  static Comentario fromJson(Map<String, dynamic> json) {
    String? replyUsername;
    if (json.containsKey("reply_username") &&
        json["reply_username"].containsKey("full_name")) {
      replyUsername = json["reply_username"]["full_name"];
    }
    return Comentario(
      text: json["text"],
      commentId: json["comment_id"],
      createdAt: json["created_at"],
      postId: json["post_id"],
      curtidoPorMim: json["curtido_por_mim"] ?? false,
      commentAboveId: json["comment_above_id"],
      userReplyId: json["user_reply_id"],
      commentReplyId: json['comment_reply_id'],
      curtidas: json["total_curtidas_comentario"] ?? 0,
      comentariosAbaixo: json["total_comentarios_comentario"] ?? 0,
      usuario: Usuario.fromJson(json["usuario"]),
      replyUsername: replyUsername,
    );
  }
}

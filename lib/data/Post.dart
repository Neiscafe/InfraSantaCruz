import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'Usuario.dart';

class PostMidia {
  final String publicUrl;
  final String mime;

  PostMidia({required this.publicUrl, required this.mime});

  static PostMidia fromMap(Map<String, dynamic> map) {
    debugPrint(jsonEncode(map));
    return PostMidia(publicUrl: map['public_url'], mime: map['mime']);
  }

  Map<String, dynamic> toMap() {
    return {"public_url": publicUrl, "mime": mime};
  }
}

class Post {
  final String id;
  final String titulo;
  final String descricao;
  final String referenciaLocalizacao;
  final double lon;
  final double lat;
  final int totalCurtidas;
  final bool curtidoPorMim;
  final int totalComentarios;
  final String rua;
  final String bairro;
  final String cidade;
  final String cep;
  final String jsonEndereco;
  final List<PostMidia> jsonMidias;
  final Usuario usuario;
  final String createdAt;

  Post({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.referenciaLocalizacao,
    required this.lon,
    required this.lat,
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.jsonEndereco,
    required this.jsonMidias,
    required this.createdAt,
    required this.usuario,
    this.totalCurtidas = 0,
    this.curtidoPorMim = false,
    this.totalComentarios = 0,
  });

  Post copy({
    String? id,
    String? titulo,
    String? descricao,
    String? referenciaLocalizacao,
    double? lon,
    double? lat,
    String? rua,
    String? bairro,
    String? cidade,
    String? cep,
    String? jsonEndereco,
    List<PostMidia>? jsonMidias,
    String? createdAt,
    Usuario? usuario,
    bool? curtidoPorMim,
    int? totalCurtidas,
    int? totalComentarios,
  }) {
    return Post(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      referenciaLocalizacao:
          referenciaLocalizacao ?? this.referenciaLocalizacao,
      lon: lon ?? this.lon,
      lat: lat ?? this.lat,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      jsonEndereco: jsonEndereco ?? this.jsonEndereco,
      jsonMidias: jsonMidias ?? this.jsonMidias,
      createdAt: createdAt ?? this.createdAt,
      curtidoPorMim: curtidoPorMim ?? this.curtidoPorMim,
      usuario: usuario ?? this.usuario,
      totalCurtidas: totalCurtidas ?? this.totalCurtidas,
      totalComentarios: totalComentarios ?? this.totalComentarios,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    debugPrint(jsonEncode(json));
    final post = Post(
      id: json['post_id'],
      titulo: json['titulo'],
      referenciaLocalizacao: json['referencia_local'] ?? '',
      descricao: json['descricao'],
      lon: json['lon'],
      lat: json['lat'],
      rua: json['rua'],
      totalCurtidas: json['total_curtidas'],
      curtidoPorMim: json['curtido_por_mim'],
      totalComentarios: json['total_comentarios'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      cep: json['cep'],
      jsonEndereco: json['json_endereco'],
      jsonMidias: (jsonDecode(json["json_midias"] ?? "") as List<dynamic>)
          .map((map) => PostMidia.fromMap(map))
          .toList(),
      createdAt: json['created_at'],
      usuario: Usuario.fromJson(json["usuario"]),
    );
    debugPrint(jsonEncode(post.toJson()));
    return post;
  }

  Map<String, dynamic> toJson() {
    return {
      "post_id": id,
      "titulo": titulo,
      "descricao": descricao,
      "lon": lon,
      "lat": lat,
      "usuario_id": usuario.usuarioId,
      "referencia_local": referenciaLocalizacao,
      "rua": rua,
      "bairro": bairro,
      "cidade": cidade,
      "cep": cep,
      "json_midias": jsonEncode(
        jsonMidias.map((postMidia) => postMidia.toMap()).toList(),
      ),
      "json_endereco": jsonEndereco,
    };
  }

  late DateTime createdDateTime = DateTime.parse(createdAt);
}

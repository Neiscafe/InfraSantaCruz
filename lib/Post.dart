import 'dart:convert';

import 'package:myapp/AuthRepository.dart';

class PostMidia {
  final String publicUrl;
  final String mime;

  PostMidia({required this.publicUrl, required this.mime});

  static PostMidia fromMap(Map<String, dynamic> map) {
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
  final String rua;
  final String bairro;
  final String cidade;
  final String cep;
  final String jsonEndereco;
  final List<PostMidia> jsonMidias;
  final String usuarioId;

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
    String? usuarioId,
    this.totalCurtidas = 0,
    this.curtidoPorMim = false,
  }) : usuarioId = usuarioId ??= AuthRepository.session!.user.id;

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
    String? usuarioId,
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
    );
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['post_id'],
      titulo: map['titulo'],
      referenciaLocalizacao: map['referencia_local'] ?? '',
      descricao: map['descricao'],
      usuarioId: map['usuario_id'],
      lon: map['lon'],
      lat: map['lat'],
      rua: map['rua'],
      totalCurtidas: map['total_curtidas'],
      curtidoPorMim: map['curtido_por_mim'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      cep: map['cep'],
      jsonEndereco: map['json_endereco'],
      jsonMidias:
          (map["json_midias"] as List<Map<String, dynamic>>?)
              ?.map((map) => PostMidia.fromMap(map))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "post_id": id,
      "titulo": titulo,
      "descricao": descricao,
      "lon": lon,
      "lat": lat,
      "usuario_id": usuarioId,
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
}

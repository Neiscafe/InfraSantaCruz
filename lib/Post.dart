class Post {
  final String id;
  final String titulo;
  final String descricao;
  final String referenciaLocalizacao;
  final double lon;
  final double lat;
  final String rua;
  final String bairro;
  final String cidade;
  final String cep;
  final String jsonEndereco;

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
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      titulo: map['titulo'],
      referenciaLocalizacao: map['referenciaLocalizacao'] ?? '',
      descricao: map['descricao'],
      lon: map['lon'],
      lat: map['lat'],
      rua: map['rua'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      cep: map['cep'],
      jsonEndereco: map['jsonDados'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "titulo": titulo,
      "descricao": descricao,
      "lon": lon,
      "lat": lat,
      "referenciaLocalizacao": referenciaLocalizacao,
      "rua": rua,
      "bairro": bairro,
      "cidade": cidade,
      "cep": cep,
      "jsonEndereco": jsonEndereco,
    };
  }
}

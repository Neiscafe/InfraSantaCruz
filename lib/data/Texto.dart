import 'package:flutter/cupertino.dart';

class Texto {
  static final _controle = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );
  static final _espacosRepetidos = RegExp(r'[ \t]{2,}');

  static String limpar(String s, {int max = 1000}) {
    final t = s
        .replaceAll(_controle, '')
        .replaceAll(_espacosRepetidos, ' ')
        .trim();
    return t.characters.take(max).toString(); // não corta emoji ao meio
  }

  static final _endereco = RegExp(
    r"^[\p{L}\p{M}0-9 .,'ºª\-/]{1,100}$",
    unicode: true,
  );

  static String? validaEndereco(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return _endereco.hasMatch(v.trim()) ? null : "Caracteres inválidos";
  }

  static String escapaLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}

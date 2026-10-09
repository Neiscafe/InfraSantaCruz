import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myapp/data/repository/PostsRepository.dart';
import 'package:myapp/feature/posts/PostDetailsScreen.dart';

import '../data/repository/AuthRepository.dart';

/// Decide para onde o app vai quando o usuário toca em uma notificação.
///
/// Regra: o post só é aberto quando (1) o navigator existe, (2) há sessão
/// válida e (3) a HomePage (feed) já está na pilha. Enquanto isso o destino
/// fica pendente. Assim, no app encerrado, o fluxo normal
/// (Splash -> login/permissões -> HomePage) roda primeiro e o post entra por
/// cima do feed; ao tocar em voltar o usuário cai no feed, e não fecha o app.
class NotificationRouter {
  static String? _postIdPendente;
  static DateTime? _pendenteDesde;
  static int _homesNaPilha = 0;
  static bool _abrindo = false;

  static const Duration _validade = Duration(minutes: 2);

  /// Chamado no initState da HomePage (ela está na pilha enquanto montada).
  static void homeMontada() {
    _homesNaPilha++;
    // Espera o primeiro frame para não empilhar durante a transição da Home.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tentarAbrir());
  }

  /// Chamado no dispose da HomePage.
  static void homeRemovida() {
    if (_homesNaPilha > 0) _homesNaPilha--;
  }

  /// Toque em notificação exibida pelo sistema (FCM): usa RemoteMessage.data.
  static void aoTocarNotificacaoFcm(Map<String, dynamic> data) =>
      _registrar(data);

  /// Toque em notificação local: o payload é o JSON do RemoteMessage.data.
  static void aoTocarNotificacaoLocal(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) _registrar(data);
    } catch (e) {
      debugPrint('Payload de notificação inválido: $e');
    }
  }

  static void _registrar(Map<String, dynamic> data) {
    final postId = data['post_id']?.toString();
    if (postId == null || postId.isEmpty) return;
    _postIdPendente = postId;
    _pendenteDesde = DateTime.now();
    _tentarAbrir();
  }

  static Future<void> _tentarAbrir() async {
    final postId = _postIdPendente;
    if (postId == null || _abrindo) return;

    if (DateTime.now().difference(_pendenteDesde!) > _validade) {
      _postIdPendente = null; // pendência velha: descarta
      return;
    }

    final navigator = AuthRepository.navigatorKey.currentState;
    if (navigator == null ||
        !AuthRepository.isAuthenticated ||
        _homesNaPilha == 0) {
      return; // continua pendente até o feed aparecer
    }

    _abrindo = true;
    _postIdPendente = null;
    try {
      final post = await PostsRepository.buscaPost(postId);
      final nav = AuthRepository.navigatorKey.currentState;
      if (nav == null) return;
      if (post == null) {
        _avisar('Essa publicação não está mais disponível.');
        return;
      }
      nav.push(
        MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
      );
    } catch (e) {
      debugPrint('Erro ao abrir post da notificação: $e');
      _avisar('Não foi possível abrir a publicação.');
    } finally {
      _abrindo = false;
      if (_postIdPendente != null)
        _tentarAbrir(); // outro toque durante a busca
    }
  }

  static void _avisar(String mensagem) {
    final context = AuthRepository.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

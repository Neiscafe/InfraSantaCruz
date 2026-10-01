import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/AuthRepository.dart';

import 'Comentario.dart';
import 'Consts.dart';
import 'DisplayPictureScreen.dart';
import 'DisplayVideoScreen.dart';
import 'Post.dart';
import 'PostsRepository.dart';
import 'UserPage.dart';

class VisualizaPostPage extends StatefulWidget {
  final Post post;

  const VisualizaPostPage({super.key, required this.post});

  @override
  _VisualizaPostPageState createState() => _VisualizaPostPageState();
}

class _VisualizaPostPageState extends State<VisualizaPostPage> {
  late Post post;
  Timer? _likeDebounceTimer;
  bool? _initialCurtidoPorMim;

  final Map<String, Timer> _commentLikeDebounceTimers = {};
  final Map<String, bool> _commentInitialCurtido = {};
  final Map<String, Comentario> _commentLatestState = {};

  bool finalPage = false;
  bool loading = true;
  bool silentLoading = false;
  List<Comentario> comments = List.empty();
  final ScrollController scrollController = ScrollController();
  final comentarioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _postWidget()),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.jsonMidias.length,
                  itemBuilder: (context, index) {
                    return FeedMediaItem(
                      midia: post.jsonMidias[index],
                      width: 200,
                      height: 200,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: _controlesPostWidget()),
            SliverToBoxAdapter(child: _escreverComentarioWidget()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: comments.length,
                (context, index) {
                  return _comentarioWidget(index);
                },
              ),
            ),
            if (!finalPage && !silentLoading && !loading)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      listCommentsSilently(context);
                    },
                    child: Row(
                      spacing: 4,
                      children: [Icon(Icons.add), Text("Ver mais")],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Column _postWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _usuarioWidget(),
        SizedBox(height: 24),
        Text(
          post.titulo,
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 4),
        Text(
          post.descricao,
          style: TextStyle(color: Colors.grey[900], fontSize: 16),
        ),
        SizedBox(height: 24),
        Row(
          spacing: 8,
          children: [
            Icon(Icons.date_range, color: Colors.grey[900]),
            _dataPostagemWidget(),
          ],
        ),
        SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            Icon(Icons.place, color: Colors.grey[900]),
            Expanded(
              child: Text(
                "${post.bairro}, ${post.rua}, ${post.referenciaLocalizacao}",
                style: TextStyle(color: Colors.grey[900]),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Row _controlesPostWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: exibeEscreverComentario,
          style: IconButton.styleFrom(
            minimumSize: Size.square(20),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            spacing: 12,
            children: [
              Icon(Icons.comment_outlined, color: Colors.grey),
              Text(
                "${post.totalComentarios}",
                style: TextStyle(fontSize: 16, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            if (post.curtidoPorMim) {
              descurtePost(post);
            } else {
              curtePost(post);
            }
          },
          style: IconButton.styleFrom(
            minimumSize: Size.square(20),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            spacing: 12,
            children: [
              Icon(
                post.curtidoPorMim ? Icons.favorite : Icons.favorite_border,
                color: post.curtidoPorMim ? Colors.red : Colors.grey,
              ),
              Text(
                post.totalCurtidas.toString(),
                style: TextStyle(fontSize: 16, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row _usuarioWidget() {
    return Row(
      children: [
        GestureDetector(
          onTapUp: (_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (contenxt) => UserPage(user: post.usuario),
              ),
            );
          },
          child: CachedNetworkImage(
            width: 40,
            height: 40,
            imageUrl: post.usuario.urlAvatar ?? "",
            imageBuilder: (context, provider) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(image: provider, fit: BoxFit.fill),
                ),
              );
            },
            placeholder: (context, url) => Icon(Icons.account_circle),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.usuario.fullName,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              Text(
                "@${post.usuario.fullName.replaceAll(" ", "")}",
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Builder _dataPostagemWidget() {
    return Builder(
      builder: (context) {
        String text;
        var createdDateTime = post.createdDateTime;
        int epochPost = createdDateTime.millisecondsSinceEpoch;
        int epochNow = DateTime.now().millisecondsSinceEpoch;
        int diffNowPost = epochNow - epochPost;
        int vinteQuatroHoras = 86400000;
        int sessentaMinutos = 60000;
        if (diffNowPost < sessentaMinutos) {
          text = "Postado ${(diffNowPost / 1000 / 60).toInt()} minutos atrás";
        } else if (diffNowPost <= vinteQuatroHoras) {
          text =
              "Postado ${(diffNowPost / 1000 / 60 / 60).toInt()} horas atrás";
        } else {
          String day = "${createdDateTime.day}".padLeft(2, '0');
          String month = "${createdDateTime.month}".padLeft(2, '0');
          String hour = "${createdDateTime.hour}".padLeft(2, '0');
          String minute = "${createdDateTime.minute}".padLeft(2, '0');
          text = "Postado em $day/$month/${createdDateTime.year} $hour:$minute";
        }
        return Text(text, style: TextStyle(color: Colors.grey[900]));
      },
    );
  }

  Padding _comentarioWidget(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: CommentItem(
        canExpand: true,
        comentario: comments[index],
        carregaRespostas: (Comentario comentario) {
          String? maisAntiga = null;
          if (comentario.respostas.isNotEmpty) {
            var ordenada = comentario.respostas.toList();
            ordenada.sort(
              (c1, c2) => c1.createdDateTime.compareTo(c2.createdDateTime),
            );
            maisAntiga = ordenada.last.createdAt;
          }
          carregaRespostas(comentario, maisAntiga);
        },
        escreverResposta: (Comentario comentarioResposta) {
          exibeEscreverResposta(comments[index], comentarioResposta);
        },
        curteComentario: curteComentario,
        descurteComentario: descurteComentario,
      ),
    );
  }

  Column _escreverComentarioWidget() {
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Card.filled(
                margin: EdgeInsetsGeometry.all(0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTapUp: (details) {
                    exibeEscreverComentario();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Escreva um comentário"),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _onCommentLikeToggled(Comentario comentario) {
    final commentId = comentario.commentId;

    _commentInitialCurtido[commentId] ??= comentario.curtidoPorMim;

    final novoCurtido = !comentario.curtidoPorMim;
    final novasCurtidas = novoCurtido
        ? comentario.curtidas + 1
        : comentario.curtidas - 1;

    final comentarioAtualizado = comentario.copy(
      curtidoPorMim: novoCurtido,
      curtidas: novasCurtidas,
    );

    _commentLatestState[commentId] = comentarioAtualizado;

    setState(() {
      if (comentario.commentAboveId == null) {
        var _comments = comments.toList();
        final idx = _comments.indexWhere((c) => c.commentId == commentId);
        if (idx != -1) {
          _comments[idx] = comentarioAtualizado;
          comments = _comments;
        }
      } else {
        var _comments = comments.toList();
        int? iComentarioAcima;
        Comentario? comentarioAcima;
        for (var (i, comment) in _comments.indexed) {
          if (comment.commentId == comentario.commentAboveId) {
            iComentarioAcima = i;
            comentarioAcima = comment;
            break;
          }
        }
        if (comentarioAcima != null && iComentarioAcima != null) {
          List<Comentario> _respostas = comentarioAcima.respostas.toList();
          final idx = _respostas.indexWhere((r) => r.commentId == commentId);
          if (idx != -1) {
            _respostas[idx] = comentarioAtualizado;
            _comments[iComentarioAcima] = comentarioAcima.copy(
              respostas: _respostas,
            );
            comments = _comments;
          }
        }
      }
    });

    _commentLikeDebounceTimers[commentId]?.cancel();
    _commentLikeDebounceTimers[commentId] = Timer(
      const Duration(milliseconds: 500),
      () => _syncCommentLikeWithServer(commentId),
    );
  }

  void _syncCommentLikeWithServer(String commentId) {
    _commentLikeDebounceTimers[commentId]?.cancel();
    _commentLikeDebounceTimers.remove(commentId);

    final initialCurtido = _commentInitialCurtido.remove(commentId);
    final latestComment = _commentLatestState.remove(commentId);

    if (initialCurtido != null &&
        latestComment != null &&
        initialCurtido != latestComment.curtidoPorMim) {
      if (latestComment.curtidoPorMim) {
        PostsRepository.curteComentario(latestComment);
      } else {
        PostsRepository.descurteComentario(latestComment);
      }
    }
  }

  void descurteComentario(Comentario comentario) {
    _onCommentLikeToggled(comentario);
  }

  void curteComentario(Comentario comentario) {
    _onCommentLikeToggled(comentario);
  }

  Future<void> escreverComentario(Comentario comentario) async {
    try {
      final response = await PostsRepository.criaComentario(comentario);
      final updatedPost = post.copy(
        totalComentarios: post.totalComentarios + 1,
      );
      setState(() {
        post = updatedPost;
        var _comments = comments.toList();
        _comments.insert(0, response);
        comments = _comments;
      });
      PostsRepository.notifyPostUpdated(updatedPost);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Comentário enviado")));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
  }

  void carregaRespostas(
    Comentario comentario,
    String? dataRespostaMaisAntiga,
  ) async {
    bool erro = false;
    List<Comentario>? novasRespostas;
    try {
      novasRespostas = await PostsRepository.buscaRespostas(
        comentario,
        dataRespostaMaisAntiga,
      );
    } catch (e, trace) {
      erro = true;
    }
    if (erro && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
    setState(() {
      if (novasRespostas != null) {
        var _comments = comments.toList();
        var _respostas = comentario.respostas.toList();
        _respostas.addAll(novasRespostas);
        var index = _comments.indexOf(comentario);
        _comments[index] = comentario.copy(respostas: _respostas);
        comments = _comments;
      }
    });
  }

  void listCommentsSilently(BuildContext context) async {
    setState(() {
      silentLoading = true;
    });
    bool erro = false;
    List<Comentario>? novosComentarios;
    var comentariosOrdenados = comments.toList();
    comentariosOrdenados.sort(
      (i1, i2) => i1.createdDateTime.compareTo(i2.createdDateTime),
    );
    try {
      novosComentarios = await PostsRepository.buscaComentarios(
        widget.post,
        comentariosOrdenados.first.createdAt,
      );
    } catch (e) {
      erro = true;
    }
    if (erro && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
    setState(() {
      finalPage =
          novosComentarios != null &&
          (novosComentarios.isEmpty || novosComentarios.length < 20);
      if (novosComentarios != null) {
        var _comments = comments.toList();
        _comments.addAll(novosComentarios);
        comments = _comments;
      }
      silentLoading = false;
    });
  }

  void listComments(BuildContext context) async {
    setState(() {
      loading = true;
    });
    List<Comentario>? novosComentarios;
    bool erro = false;
    try {
      novosComentarios = await PostsRepository.buscaComentarios(
        widget.post,
        null,
      );
    } catch (e) {
      erro = true;
    }
    if (erro && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
    setState(() {
      finalPage =
          novosComentarios != null &&
          (novosComentarios.isEmpty || novosComentarios.length < 20);
      comments = novosComentarios ?? List.empty();
      loading = false;
    });
  }

  Future<void> escreverResposta(
    Comentario comentario,
    Comentario respondendo,
    Comentario acima,
  ) async {
    bool erro = false;
    Comentario? resposta = null;
    try {
      resposta = await PostsRepository.criaComentario(comentario);
    } catch (e, trace) {
      erro = true;
    }
    if (erro && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
    setState(() {
      if (resposta != null) {
        // Pega o comentário acima
        var _comments = comments.toList();
        Comentario? _commentAbove = null;
        int? _iCommentAbove = null;
        for (var (i, comment) in _comments.indexed) {
          if (comment.commentId == resposta.commentAboveId) {
            _commentAbove = comment;
            _iCommentAbove = i;
            break;
          }
        }
        if (_commentAbove == null) return;
        // Adiciona a resposta no array de respostas
        var _respostas = _commentAbove.respostas.toList();
        _respostas.add(resposta);
        _comments[_iCommentAbove!] = _commentAbove.copy(respostas: _respostas);
        comments = _comments;
      }
    });
  }

  void exibeEscreverComentario() {
    if (!context.mounted) return;
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: bottomInset + 16.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Escreva um comentário",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  controller.clear();
                  Navigator.of(context).pop();
                  await escreverComentario(
                    Comentario(
                      text: controller.text,
                      postId: post.id,
                      usuario: AuthRepository.usuarioAtual,
                    ),
                  );
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
        );
      },
    );
  }

  void exibeEscreverResposta(
    Comentario comentarioAcima,
    Comentario comentarioResposta,
  ) {
    if (!context.mounted) return;
    final TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: bottomInset + 16.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Escreva uma resposta",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  controller.clear();
                  Navigator.of(context).pop();
                  await escreverResposta(
                    Comentario(
                      text: controller.text,
                      postId: post.id,
                      commentAboveId: comentarioAcima.commentId,
                      commentReplyId: comentarioResposta.commentId,
                      userReplyId: comentarioResposta.usuario.usuarioId,
                      usuario: AuthRepository.usuarioAtual,
                    ),
                    comentarioResposta,
                    comentarioAcima,
                  );
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      post = widget.post;
    });
    listComments(context);
  }

  @override
  void dispose() {
    if (_likeDebounceTimer != null && _likeDebounceTimer!.isActive) {
      _syncLikeWithServer();
    }
    _likeDebounceTimer?.cancel();

    final pendingCommentIds = List<String>.from(
      _commentLikeDebounceTimers.keys,
    );
    for (final id in pendingCommentIds) {
      _syncCommentLikeWithServer(id);
    }
    for (final timer in _commentLikeDebounceTimers.values) {
      timer.cancel();
    }
    _commentLikeDebounceTimers.clear();

    comentarioController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _onLikeToggled(bool novoCurtido) {
    _initialCurtidoPorMim ??= post.curtidoPorMim;

    final newTotalCurtidas = novoCurtido
        ? (post.curtidoPorMim ? post.totalCurtidas : post.totalCurtidas + 1)
        : (post.curtidoPorMim ? post.totalCurtidas - 1 : post.totalCurtidas);

    final updatedPost = post.copy(
      curtidoPorMim: novoCurtido,
      totalCurtidas: newTotalCurtidas,
    );

    setState(() {
      post = updatedPost;
    });
    PostsRepository.notifyPostUpdated(updatedPost);

    _likeDebounceTimer?.cancel();
    _likeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncLikeWithServer();
    });
  }

  void _syncLikeWithServer() {
    _likeDebounceTimer?.cancel();
    _likeDebounceTimer = null;

    if (_initialCurtidoPorMim != null &&
        _initialCurtidoPorMim != post.curtidoPorMim) {
      final finalState = post.curtidoPorMim;
      _initialCurtidoPorMim = finalState;
      if (finalState) {
        PostsRepository.curtePost(post);
      } else {
        PostsRepository.descurtePost(post);
      }
    }
  }

  void descurtePost(Post targetPost) {
    _onLikeToggled(false);
  }

  void curtePost(Post targetPost) {
    _onLikeToggled(true);
  }
}

class CommentItem extends StatefulWidget {
  final ValueChanged<Comentario> curteComentario;
  final ValueChanged<Comentario> descurteComentario;
  final ValueChanged<Comentario> escreverResposta;
  final ValueChanged<Comentario> carregaRespostas;
  final bool canExpand;
  final Comentario comentario;

  bool get expandido => canExpand && comentario.respostas.isNotEmpty;

  const CommentItem({
    super.key,
    required this.comentario,
    required this.curteComentario,
    required this.descurteComentario,
    required this.escreverResposta,
    required this.canExpand,
    required this.carregaRespostas,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  Comentario get comentario => widget.comentario;

  bool get canExpand => widget.canExpand;
  bool aguardandoRespostas = false;

  bool get expandido => widget.expandido;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fotoUsuarioComentarioWidget(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _usuarioComentarioWidget(),
                  _comentarioWidget(),
                  _controlaRespostasWidget(),
                ],
              ),
            ),

            _curteComentarioWidget(),
          ],
        ),
        if (expandido)
          for (var resposta in comentario.respostas) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 0.0, 0.0, 0.0),
              child: CommentItem(
                canExpand: false,
                comentario: resposta,
                carregaRespostas: widget.carregaRespostas,
                curteComentario: widget.curteComentario,
                descurteComentario: widget.descurteComentario,
                escreverResposta: widget.escreverResposta,
              ),
            ),
          ],
      ],
    );
  }

  CachedNetworkImage _fotoUsuarioComentarioWidget() {
    return CachedNetworkImage(
      width: 40,
      height: 40,
      imageUrl: comentario.usuario.urlAvatar ?? "",
      imageBuilder: (context, provider) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(image: provider, fit: BoxFit.fill),
          ),
        );
      },
      placeholder: (context, url) => Icon(Icons.account_circle),
    );
  }

  Text _usuarioComentarioWidget() {
    return Text(
      comentario.usuario.fullName,
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Text _comentarioWidget() {
    return Text.rich(
      TextSpan(
        children: [
          if (comentario.commentAboveId != null)
            TextSpan(
              text: "@${comentario.replyUsername} ",
              style: TextStyle(color: Colors.blue),
            ),
          TextSpan(text: comentario.text),
        ],
      ),
    );
  }

  Row _controlaRespostasWidget() {
    return Row(
      children: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          onPressed: () {
            widget.escreverResposta(comentario);
          },
          child: Text("Responder"),
        ),
        if (comentario.comentariosAbaixo > 0 && !expandido)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () {
              setState(() {
                aguardandoRespostas = true;
              });
              widget.carregaRespostas(comentario);
            },
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_up),
                Text("Ver respostas (${comentario.comentariosAbaixo})"),
              ],
            ),
          ),
      ],
    );
  }

  TextButton _curteComentarioWidget() {
    return TextButton(
      onPressed: () {
        if (comentario.curtidoPorMim) {
          widget.descurteComentario(comentario);
        } else {
          widget.curteComentario(comentario);
        }
      },
      style: IconButton.styleFrom(
        minimumSize: Size.square(20),
        backgroundColor: Colors.transparent,
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            comentario.curtidoPorMim ? Icons.favorite : Icons.favorite_border,
            color: comentario.curtidoPorMim ? Colors.red : Colors.grey,
          ),
          Text(
            comentario.curtidas.toString(),
            style: TextStyle(fontSize: 16, color: Colors.grey[900]),
          ),
        ],
      ),
    );
  }
}

class FeedMediaItem extends StatefulWidget {
  final int width;
  final int height;

  const FeedMediaItem({
    super.key,
    required this.midia,
    required this.width,
    required this.height,
  });

  final PostMidia midia;

  @override
  State<FeedMediaItem> createState() => _FeedMediaItemState();
}

class _FeedMediaItemState extends State<FeedMediaItem> {
  Future<File>? _thumbFuture;
  bool _abrindo = false;

  String get url => widget.midia.publicUrl;

  String get mimeType => widget.midia.mime;

  double get width => widget.width.toDouble();

  double get height => widget.height.toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mimeType.contains("image/")) {
      precacheImage(NetworkImage(url), this.context);
    }
  }

  @override
  void initState() {
    super.initState();
    if (mimeType.contains("video/")) {
      _thumbFuture = PostsRepository.thumbnailVideo(widget.midia);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (mimeType.contains("image/")) {
          return _imageWidget();
        } else if (mimeType.contains("video/")) {
          return _videoWidget();
        } else {
          return SizedBox(
            width: width,
            height: height,
            child: Container(color: Theme.of(context).colorScheme.tertiary),
          );
        }
      },
    );
  }

  Widget _videoWidget() {
    return FutureBuilder<File>(
      future: _thumbFuture,
      initialData: PostsRepository.thumbnailEmCache(widget.midia),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorWidget(context);
        }
        if (!snapshot.hasData) {
          return _loadingWidget();
        }
        return SizedBox(
          width: width,
          height: height,
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _abrirVideo,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.file(
                    snapshot.requireData,
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                  ),
                  Center(
                    child: _abrindo
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(
                            Icons.play_circle,
                            color: Colors.white,
                            size: 48,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirVideo() async {
    if (_abrindo) return;
    setState(() => _abrindo = true);
    try {
      final file = await PostsRepository.downloadVideo(widget.midia);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DisplayVideoScreen(imagePath: file.path, readOnly: true),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Consts.ERROR)));
    } finally {
      if (mounted) setState(() => _abrindo = false);
    }
  }

  CachedNetworkImage _imageWidget() {
    return CachedNetworkImage(
      fit: BoxFit.fill,
      imageUrl: url,
      imageBuilder: (context, provider) {
        return GestureDetector(
          onTap: () {
            DefaultCacheManager().getFileFromCache(url).then((fileInfo) {
              if (!context.mounted) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return DisplayPictureScreen(imagePath: fileInfo!.file.path);
                  },
                ),
              );
            });
          },
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(image: provider, fit: BoxFit.fill),
            ),
            height: height,
          ),
        );
      },
      placeholder: (context, url) {
        return _loadingWidget();
      },
      errorWidget: (context, url, error) {
        return _errorWidget(context);
      },
    );
  }

  Card _loadingWidget() {
    return Card(
      margin: EdgeInsets.all(0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(14),
        ),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10)),
      ),
    );
  }

  SizedBox _errorWidget(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.camera_alt_outlined),
      ),
    );
  }
}

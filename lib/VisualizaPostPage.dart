import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/AuthRepository.dart';

import 'Comentario.dart';
import 'DisplayPictureScreen.dart';
import 'DisplayVideoScreen.dart';
import 'Post.dart';
import 'PostsRepository.dart';
import 'VideoThumbnailWidget.dart';

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
  bool finalPage = false;
  bool loading = true;
  bool silentLoading = false;
  List<Comentario> comments = List.empty();
  final ScrollController scrollController = ScrollController();
  final comentarioController = TextEditingController();

  void descurteComentario(Comentario comentario) async {
    try {
      setState(() {
        if (comentario.commentAboveId == null) {
          var _comments = comments.toList();
          _comments[_comments.indexOf(comentario)] = comentario.copy(
            curtidoPorMim: false,
            curtidas: comentario.curtidas - 1,
          );
          comments = _comments;
        } else {
          // Pega comentário acima
          var _comments = comments.toList();
          int? iComentarioAcima = null;
          Comentario? comentarioAcima = null;
          for (var (i, comment) in _comments.indexed) {
            if (comment.commentId == comentario.commentAboveId) {
              iComentarioAcima = i;
              comentarioAcima = comment;
              break;
            }
          }
          // Pega resposta a ser alterada no comentário acima
          List<Comentario> _respostas = comentarioAcima!.respostas.toList();
          for (var (i, resposta) in _respostas.indexed) {
            if (resposta.commentId == comentario.commentId) {
              // Altera a resposta
              _respostas[i] = comentario.copy(
                curtidoPorMim: false,
                curtidas: comentario.curtidas - 1,
              );
              // Altera o comentário acima
              _comments[iComentarioAcima!] = comentarioAcima.copy(
                respostas: _respostas,
              );
              comments = _comments;
            }
          }
        }
      });
      PostsRepository.descurteComentario(comentario);
    } catch (e, trace) {}
  }

  void curteComentario(Comentario comentario) {
    try {
      setState(() {
        if (comentario.commentAboveId == null) {
          var _comments = comments.toList();
          _comments[_comments.indexOf(comentario)] = comentario.copy(
            curtidoPorMim: true,
            curtidas: comentario.curtidas + 1,
          );
          comments = _comments;
        } else {
          // Pega comentário acima
          var _comments = comments.toList();
          int? iComentarioAcima = null;
          Comentario? comentarioAcima = null;
          for (var (i, comment) in _comments.indexed) {
            if (comment.commentId == comentario.commentAboveId) {
              iComentarioAcima = i;
              comentarioAcima = comment;
              break;
            }
          }
          // Pega resposta a ser alterada no comentário acima
          List<Comentario> _respostas = comentarioAcima!.respostas.toList();
          for (var (i, resposta) in _respostas.indexed) {
            if (resposta.commentId == comentario.commentId) {
              // Altera a resposta
              _respostas[i] = comentario.copy(
                curtidoPorMim: true,
                curtidas: comentario.curtidas + 1,
              );
              // Altera o comentário acima
              _comments[iComentarioAcima!] = comentarioAcima.copy(
                respostas: _respostas,
              );
              comments = _comments;
            }
          }
        }
      });
      PostsRepository.curteComentario(comentario);
    } catch (e, trace) {}
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
    comentarioController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(
                        width: 40,
                        height: 40,
                        imageUrl: post.usuario.urlAvatar ?? "",
                        imageBuilder: (context, provider) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: provider,
                                fit: BoxFit.fill,
                              ),
                            ),
                          );
                        },
                        placeholder: (context, url) =>
                            Icon(Icons.account_circle),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.usuario.fullName,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.titulo,
                          style: TextStyle(color: Colors.black, fontSize: 24),
                        ),
                      ),
                      Text(post.totalCurtidas.toString()),
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
                          foregroundColor: post.curtidoPorMim
                              ? Colors.red
                              : Colors.grey,
                        ),
                        child: Icon(
                          post.curtidoPorMim
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    post.descricao,
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.date_range),
                      Builder(
                        builder: (context) {
                          String text;
                          var createdDateTime = post.createdDateTime;
                          int epochPost =
                              createdDateTime.millisecondsSinceEpoch;
                          int epochNow = DateTime.now().millisecondsSinceEpoch;
                          int diffNowPost = epochNow - epochPost;
                          int vinteQuatroHoras = 86400000;
                          int sessentaMinutos = 60000;
                          if (diffNowPost < sessentaMinutos) {
                            text =
                                "Postado ${(diffNowPost / 1000 / 60).toInt()} minutos atrás";
                          } else if (diffNowPost <= vinteQuatroHoras) {
                            text =
                                "Postado ${(diffNowPost / 1000 / 60 / 60).toInt()} horas atrás";
                          } else {
                            String day = "${createdDateTime.day}".padLeft(
                              2,
                              '0',
                            );
                            String month = "${createdDateTime.month}".padLeft(
                              2,
                              '0',
                            );
                            String hour = "${createdDateTime.hour}".padLeft(
                              2,
                              '0',
                            );
                            String minute = "${createdDateTime.minute}".padLeft(
                              2,
                              '0',
                            );
                            text =
                                "Postado em $day/$month/${createdDateTime.year} $hour:$minute";
                          }
                          return Text(text);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.place),
                      Text(
                        "${post.bairro}, ${post.rua}, ${post.referenciaLocalizacao}",
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
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
            SliverToBoxAdapter(
              child: Column(
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
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: comments.length,
                (context, index) {
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
                            (c1, c2) => c1.createdDateTime.compareTo(
                              c2.createdDateTime,
                            ),
                          );
                          maisAntiga = ordenada.last.createdAt;
                        }
                        carregaRespostas(comentario, maisAntiga);
                      },
                      escreverResposta: (Comentario comentarioResposta) {
                        exibeEscreverResposta(
                          comments[index],
                          comentarioResposta,
                        );
                      },
                      curteComentario: curteComentario,
                      descurteComentario: descurteComentario,
                    ),
                  );
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
            CachedNetworkImage(
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
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comentario.usuario.fullName,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (comentario.commentAboveId != null)
                          TextSpan(
                            text: "@${comentario.replyUsername}",
                            style: TextStyle(color: Colors.blue),
                          ),
                        TextSpan(text: " ${comentario.text}"),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          widget.escreverResposta(comentario);
                        },
                        child: Text("Responder"),
                      ),
                      if (comentario.comentariosAbaixo > 0 && !expandido)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              aguardandoRespostas = true;
                            });
                            widget.carregaRespostas(comentario);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.keyboard_arrow_up),
                              Text(
                                "Ver respostas (${comentario.comentariosAbaixo})",
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              children: [
                Text(comentario.curtidas.toString()),
                TextButton(
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
                    foregroundColor: comentario.curtidoPorMim
                        ? Colors.red
                        : Colors.grey,
                  ),
                  child: Icon(
                    comentario.curtidoPorMim
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                ),
              ],
            ),
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
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (mimeType.contains("image/")) {
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
                          return DisplayPictureScreen(
                            imagePath: fileInfo!.file.path,
                          );
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
                  child: Card(
                    color: Colors.transparent,
                    elevation: 0,
                    child: Center(child: Icon(Icons.photo_camera)),
                  ),
                ),
              );
            },
            placeholder: (context, url) {
              return Card(
                margin: EdgeInsets.all(0),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) {
              return SizedBox(
                width: width,
                height: height,
                child: Card(
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(Icons.camera_alt_outlined),
                ),
              );
            },
          );
        } else if (mimeType.contains("video/")) {
          return FutureBuilder(
            future: PostsRepository.downloadVideo(widget.midia),
            builder: (context, snapshot) {
              final file = snapshot.data != null
                  ? XFile(snapshot.data!.path)
                  : null;
              if (!snapshot.hasError && !snapshot.hasData) {
                return Card(
                  margin: EdgeInsets.all(0),
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  width: width,
                  height: height,
                  child: Card(
                    color: Theme.of(context).colorScheme.error,
                    child: Center(
                      child: Icon(Icons.video_camera_back_outlined),
                    ),
                  ),
                );
              }
              return SizedBox(
                width: width,
                height: height,
                child: Card(
                  child: InkWell(
                    onTapUp: (_) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DisplayVideoScreen(
                          imagePath: file!.path,
                          readOnly: true,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.video_camera_back),
                        ),
                        VideoThumbnailWidget(file: XFile(snapshot.data!.path)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
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
}

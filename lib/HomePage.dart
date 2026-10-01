import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/DisplayVideoScreen.dart';
import 'package:myapp/PhotoMenuPage.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/UserPage.dart';
import 'package:myapp/VideoThumbnailWidget.dart';
import 'package:myapp/VisualizaPostPage.dart';

import 'Post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = List.empty();
  bool loading = true;
  bool silentLoading = false;
  int currentPage = 0;
  bool finalPage = false;
  StreamSubscription<Post>? _streamSubscription;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshPosts(this.context);
    });
    scrollController.addListener(() {
      final scrollableSize = scrollController.position.maxScrollExtent;
      final itemSize = scrollableSize / posts.length;
      final remainingItemsThreshold = itemSize * 20;
      if (scrollableSize - scrollController.position.pixels <=
              remainingItemsThreshold &&
          !loading &&
          currentPage > 0 &&
          !finalPage) {
        listPostsSilently(this.context, currentPage);
      }
    });
    _streamSubscription = PostsRepository.onPostUpdated.listen((Post post) {
      setState(() {
        var _posts = List.of(posts);
        _posts[posts.indexWhere((post2) => post2.id == post.id)] = post;
        posts = _posts;
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => PhotoMenuPage()));
        },
      ),
      appBar: AppBar(
        leading: SizedBox.shrink(),
        title: Text('Feed de Posts'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: UserIconWidget(
              url: AuthRepository.usuarioAtual.urlAvatar ?? "",
              onTap: (_) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      UserPage(user: AuthRepository.usuarioAtual),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (loading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Flexible(
                  child: RefreshIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.blue,
                    onRefresh: () => refreshPosts(context),
                    elevation: 4,
                    child: ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(),
                      controller: scrollController,
                      padding: EdgeInsets.all(12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return PostCardWidget(
                          post,
                          navega: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return VisualizaPostPage(post: post);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> refreshPosts(BuildContext context) async {
    if (!context.mounted) return;
    setState(() {
      loading = true;
    });
    List<Post>? posts;
    String? erro;
    try {
      posts = await PostsRepository.buscaPosts(null, null);
    } catch (e) {
      erro = Consts.ERROR;
    }
    if (!context.mounted) return;
    erro != null
        ? ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(Consts.ERROR)))
        : null;
    setState(() {
      finalPage = false;
      loading = false;
      currentPage = 1;
      this.posts = posts ?? this.posts;
    });
  }

  Future<void> listPostsSilently(BuildContext context, int currentPage) async {
    if (!context.mounted) return;
    setState(() {
      loading = true;
    });
    List<Post>? novosPosts;
    String? error;
    try {
      novosPosts = await PostsRepository.buscaPosts(posts.last.createdAt, null);
    } catch (e) {
      error = Consts.ERROR;
    }
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
    setState(() {
      loading = false;
      if (error == null && novosPosts!.isEmpty || novosPosts!.length < 20) {
        finalPage = true;
        return;
      }
      final postsCopy = posts.toList();
      postsCopy.addAll(novosPosts ?? posts);
      currentPage = error == null ? currentPage + 1 : currentPage;
      posts = postsCopy;
    });
  }
}

class PostCardWidget extends StatefulWidget {
  final Post post;
  final VoidCallback navega;

  const PostCardWidget(this.post, {super.key, required this.navega});

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  late bool curtido;
  late int numCurtidas;
  late int numComentarios;
  Timer? _likeDebounceTimer;
  bool? _initialCurtido;

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    _syncWithWidget();
  }

  @override
  void didUpdateWidget(covariant PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post ||
        oldWidget.post.curtidoPorMim != widget.post.curtidoPorMim ||
        oldWidget.post.totalCurtidas != widget.post.totalCurtidas ||
        oldWidget.post.totalComentarios != widget.post.totalComentarios) {
      _syncWithWidget();
    }
  }

  void _syncWithWidget() {
    setState(() {
      curtido = post.curtidoPorMim;
      numCurtidas = post.totalCurtidas;
      numComentarios = post.totalComentarios;
    });
  }

  void _onLikeToggled() {
    _initialCurtido ??= curtido;

    final novoCurtido = !curtido;
    final novoNumCurtidas = novoCurtido ? numCurtidas + 1 : numCurtidas - 1;

    final updatedPost = post.copy(
      curtidoPorMim: novoCurtido,
      totalCurtidas: novoNumCurtidas,
    );

    setState(() {
      curtido = novoCurtido;
      numCurtidas = novoNumCurtidas;
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

    if (_initialCurtido != null && _initialCurtido != curtido) {
      final finalState = curtido;
      _initialCurtido = finalState;
      final currentPost = post.copy(
        curtidoPorMim: finalState,
        totalCurtidas: numCurtidas,
      );
      if (finalState) {
        PostsRepository.curtePost(currentPost);
      } else {
        PostsRepository.descurtePost(currentPost);
      }
    }
  }

  @override
  void dispose() {
    if (_likeDebounceTimer != null && _likeDebounceTimer!.isActive) {
      _syncLikeWithServer();
    }
    _likeDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.grey[100],
      onTapUp: (details) {
        widget.navega();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: Colors.grey[200]),
          SizedBox(height: 16),
          _userInfo(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                if (post.referenciaLocalizacao.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[800],
                      ),
                      SizedBox(width: 4),
                      Text(
                        post.referenciaLocalizacao,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                ],
                Text(
                  post.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                ),
              ],
            ),
          ),
          _postMedias(context),
          SizedBox(height: 16),
          _postInteractionControls(),
        ],
      ),
    );
  }

  Widget _postMedias(BuildContext context) {
    return Row(
      children: [
        for (var (i, midia) in post.jsonMidias.indexed.take(3)) ...[
          FeedMediaItem(midia: midia),
          SizedBox(width: 4),
        ],
        if (post.jsonMidias.length > 3)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return VisualizaPostPage(post: post);
                  },
                ),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(Icons.add)),
            ),
          ),
      ],
    );
  }

  Widget _postInteractionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          onPressed: _onLikeToggled,
          icon: Icon(
            curtido ? Icons.favorite : Icons.favorite_border,
            color: curtido ? Colors.red : Colors.grey,
          ),
        ),
        Text("$numCurtidas"),
        IconButton(
          onPressed: widget.navega,
          icon: Icon(Icons.comment_outlined, color: Colors.grey),
        ),
        Text("$numComentarios"),
      ],
    );
  }

  Widget _userInfo() {
    return Row(
      children: [
        UserIconWidget(
          url: post.usuario.urlAvatar ?? "",
          onTap: (_) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (contenxt) => UserPage(user: post.usuario),
              ),
            );
          },
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.usuario.fullName,
                style: TextStyle(color: Colors.black, fontSize: 16),
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
}

class FeedMediaItem extends StatefulWidget {
  const FeedMediaItem({super.key, required this.midia});

  final PostMidia midia;

  @override
  State<FeedMediaItem> createState() => _FeedMediaItemState();
}

class _FeedMediaItemState extends State<FeedMediaItem> {
  String get url => widget.midia.publicUrl;

  String get mimeType => widget.midia.mime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mimeType.contains("image/")) {
      precacheImage(NetworkImage(url), this.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = 80.0;
    final height = 80.0;
    return Builder(
      builder: (context) {
        if (mimeType.contains("image/")) {
          return _imageView(width, height);
        } else if (mimeType.contains("video/")) {
          return _videoView(width, height);
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

  Widget _videoView(double width, double height) {
    return FutureBuilder(
      future: PostsRepository.downloadVideo(widget.midia),
      builder: (context, snapshot) {
        final file = snapshot.data != null ? XFile(snapshot.data!.path) : null;
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
              child: Center(child: Icon(Icons.video_camera_back_outlined)),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(14),
          child: Material(
            borderRadius: BorderRadiusGeometry.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTapUp: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayVideoScreen(
                      imagePath: file.path,
                      readOnly: true,
                    ),
                  ),
                );
              },
              child: Ink(
                width: width,
                height: height,
                decoration: BoxDecoration(color: Colors.grey[300]),
                child: Stack(
                  children: [
                    VideoThumbnailWidget(file: file!),
                    Align(
                      alignment: AlignmentGeometry.center,
                      child: Icon(Icons.play_circle, color: Colors.grey[900]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imageView(double width, double height) {
    return CachedNetworkImage(
      fit: BoxFit.fill,
      imageUrl: url,
      imageBuilder: (context, provider) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black12,
                image: DecorationImage(image: provider, fit: BoxFit.fitHeight),
              ),
            ),
          ),
          onTapUp: (details) {
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
                      readOnly: true,
                    );
                  },
                ),
              );
            });
          },
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
  }
}

class PostFilterForm extends StatefulWidget {
  final void Function(
    String bairro,
    String rua,
    ProximidadeFiltro proximidadeFiltro,
  )
  callback;

  const PostFilterForm({super.key, required this.callback});

  @override
  State<PostFilterForm> createState() => _PostFilterFormState();
}

class _PostFilterFormState extends State<PostFilterForm> {
  bool expandido = false;
  final globalKey = GlobalKey<FormState>();
  String bairroFilter = "";
  String ruaFilter = "";
  ProximidadeFiltro proximidadeFilter = ProximidadeFiltro.todaCidade;

  @override
  void initState() {
    super.initState();
  }

  void onSubmit() {
    if (globalKey.currentState!.validate()) {
      widget.callback(bairroFilter, ruaFilter, proximidadeFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () {
              setState(() {
                expandido = !expandido;
              });
            },
            icon: Builder(
              builder: (context) {
                if (expandido) {
                  return Icon(Icons.filter_alt);
                } else {
                  return Icon(Icons.filter_alt_outlined);
                }
              },
            ),
          ),
        ),
        if (expandido) ...[
          Form(
            key: globalKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 32, 16),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Filtrar por Bairro",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        bairroFilter = text;
                      });
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "Filtrar por Rua",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        ruaFilter = text;
                      });
                    },
                  ),
                  DropdownMenuFormField(
                    dropdownMenuEntries: ProximidadeFiltro.entries,
                    initialSelection: ProximidadeFiltro.todaCidade,
                    label: Text("Filtrar por Proximidade"),
                    expandedInsets: EdgeInsets.zero,
                    requestFocusOnTap: false,
                    onSelected: (proximidade) {
                      setState(() {
                        proximidadeFilter = proximidade!;
                      });
                    },
                  ),
                  FilledButton(
                    onPressed: onSubmit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Builder(
                          builder: (context) {
                            return Icon(Icons.filter_list);
                          },
                        ),
                        Text("Filtrar"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class UserIconWidget extends StatelessWidget {
  final String url;
  final ValueChanged<String> onTap;
  final Size size;
  final double borderRadius;

  const UserIconWidget({
    super.key,
    required this.url,
    required this.onTap,
    Size? size,
    double? borderRadius,
  }) : size = size ?? const Size(40, 40),
       borderRadius = borderRadius ?? 20;

  Widget _userImage() {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size.width,
        height: size.height,
        imageBuilder: (context, provider) {
          return Material(
            borderRadius: BorderRadiusGeometry.circular(borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTapUp: (_) => onTap(url),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  image: DecorationImage(image: provider, fit: BoxFit.fill),
                ),
              ),
            ),
          );
        },
        placeholder: (context, url) => Icon(Icons.account_circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _userImage();
  }
}

enum ProximidadeFiltro {
  ate1km('Até 1Km'),
  ate5km('Até 5km'),
  todaCidade('Toda cidade');

  final String label;

  const ProximidadeFiltro(this.label);

  static final List<DropdownMenuEntry<ProximidadeFiltro>> entries =
      UnmodifiableListView(
        values.map(
          (entry) => DropdownMenuEntry(value: entry, label: entry.label),
        ),
      );
}

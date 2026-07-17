import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/PhotoMenuPage.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/VideoThumbnailWidget.dart';

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
          currentPage > 0) {
        listPostsSilently(this.context, currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.large(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => PhotoMenuPage()));
        },
      ),
      appBar: AppBar(title: Text('Feed de Posts'), centerTitle: true),
      body: Column(
        children: [
          PostFilterForm(
            callback: (barro, rua, filtro) {
              refreshPosts(context);
            },
          ),
          Builder(
            builder: (context) {
              if (loading) {
                return Center(child: CircularProgressIndicator());
              }
              return Flexible(
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
                      return PostCardWidget(post);
                    },
                  ),
                ),
              );
            },
          ),
        ],
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
      posts = await PostsRepository.buscaPosts(0);
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
      loading = false;
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
      novosPosts = await PostsRepository.buscaPosts(currentPage + 1);
    } catch (e) {
      error = Consts.ERROR;
    }
    if (!context.mounted) return;
    error != null
        ? ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)))
        : null;
    setState(() {
      final postsCopy = posts.toList();
      postsCopy.addAll(novosPosts ?? posts);
      currentPage = error == null ? currentPage + 1 : currentPage;
      posts = postsCopy;
      loading = false;
    });
  }
}

class PostCardWidget extends StatefulWidget {
  final Post post;

  const PostCardWidget(this.post, {super.key});

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool curtido = false;
  int numCurtidas = 0;

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    setState(() {
      curtido = post.curtidoPorMim;
      numCurtidas = post.totalCurtidas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.pin_drop, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(post.referenciaLocalizacao),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          post.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text("$numCurtidas"),
                    IconButton(
                      onPressed: () {
                        if (curtido) {
                          PostsRepository.descurtePost(post);
                        } else {
                          PostsRepository.curtePost(post);
                        }
                        setState(() {
                          final novo = !curtido;
                          curtido = novo;
                          if (novo) {
                            numCurtidas++;
                          } else {
                            numCurtidas--;
                          }
                        });
                      },
                      icon: Builder(
                        builder: (context) {
                          if (curtido) {
                            return Icon(Icons.favorite);
                          } else {
                            return Icon(Icons.favorite_border);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: post.jsonMidias.take(4).map((postMidia) {
                return FeedMediaItem(midia: postMidia);
              }).toList(),
            ),
          ],
        ),
      ),
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
    return Builder(
      builder: (context) {
        if (mimeType.contains("image/")) {
          return Card(
            margin: EdgeInsets.all(0),
            child: SizedBox(
              width: 100,
              height: 100,
              child: AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) {
                    return Container(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    );
                  },
                  errorWidget: (context, url, error) {
                    return Container(
                      color: Theme.of(context).colorScheme.errorContainer,
                    );
                  },
                ),
              ),
            ),
          );
        } else if (mimeType.contains("video/")) {
          return FutureBuilder(
            future: PostsRepository.downloadMidia(widget.midia),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Card(
                  margin: EdgeInsets.all(0),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Container(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTap: () {},
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Card(
                      child: VideoThumbnailWidget(
                        file: XFile.fromData(snapshot.requireData),
                        onTap: (file) {},
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return SizedBox.shrink();
        }
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

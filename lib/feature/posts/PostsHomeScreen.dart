import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:myapp/consts/Consts.dart';
import 'package:myapp/data/repository/AuthRepository.dart';
import 'package:myapp/feature/posts/PostCardWidget.dart';
import 'package:myapp/feature/posts/PostCreationScreen.dart';
import 'package:myapp/feature/posts/PostsCurtidosScreen.dart';
import 'package:myapp/data/repository/PostsRepository.dart';
import 'package:myapp/feature/posts/UserPostsScreen.dart';
import 'package:myapp/feature/posts/PostDetailsScreen.dart';

import '../../data/Post.dart';
import '../NotificationRouter.dart';

class PostsHomeScreen extends StatefulWidget {
  const PostsHomeScreen({super.key});

  @override
  State<PostsHomeScreen> createState() => _PostsHomeScreenState();
}

class _PostsHomeScreenState extends State<PostsHomeScreen> {
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
    NotificationRouter.homeMontada();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshPosts(this.context);
    });
    scrollController.addListener(() {
      if (!scrollController.hasClients ||
          posts.isEmpty ||
          loading ||
          silentLoading ||
          finalPage) {
        return;
      }
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      if (maxScroll - currentScroll <= 200) {
        listPostsSilently(this.context);
      }
    });
    _streamSubscription = PostsRepository.onPostUpdated.listen((Post post) {
      final index = posts.indexWhere((p) => p.id == post.id);
      if (!mounted) return;
      if (index == -1) {
        setState(() {
          var _posts = posts.toList();
          _posts.insert(0, post);
          this.posts = _posts;
        });
        return;
      }
      setState(() {
        final novos = List.of(posts);
        novos[index] = post;
        posts = novos;
      });
    });
  }

  @override
  void dispose() {
    NotificationRouter.homeRemovida();
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
          ).push(MaterialPageRoute(builder: (_) => PostCreationScreen()));
        },
      ),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: UserIconWidget(
            url: AuthRepository.usuarioAtual.urlAvatar ?? "",
            onTap: (_) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    UserPostsScreen(user: AuthRepository.usuarioAtual),
              ),
            ),
          ),
        ),
        title: Text('Feed de Posts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.grey[900]),
            tooltip: 'Posts Curtidos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PostsCurtidosScreen(),
                ),
              );
            },
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
                    child: posts.isEmpty
                        ? CustomScrollView(
                            slivers: [
                              SliverFillRemaining(
                                child: Center(
                                  child: Text("Nenhuma publicação ainda."),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            controller: scrollController,
                            padding: EdgeInsets.all(12),
                            itemCount: posts.length + (silentLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final post = posts[index];
                              return PostCardWidget(
                                post,
                                navega: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return PostDetailsScreen(post: post);
                                      },
                                    ),
                                  );
                                },
                                onProfileTouch: (profile) =>
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (contenxt) =>
                                            UserPostsScreen(user: profile),
                                      ),
                                    ),
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
      silentLoading = false;
      finalPage = false;
    });
    List<Post>? novosPosts;
    String? erro;
    try {
      novosPosts = await PostsRepository.buscaPosts(null, null);
    } catch (e) {
      erro = Consts.ERROR;
    }
    if (!context.mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Consts.ERROR)));
    }
    setState(() {
      loading = false;
      currentPage = 1;
      if (novosPosts != null) {
        posts = novosPosts;
        if (novosPosts.isEmpty || novosPosts.length < 20) {
          finalPage = true;
        }
      }
    });
  }

  Future<void> listPostsSilently(BuildContext context) async {
    if (!context.mounted ||
        loading ||
        silentLoading ||
        finalPage ||
        posts.isEmpty) {
      return;
    }
    setState(() {
      silentLoading = true;
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
      silentLoading = false;
      if (error == null && novosPosts != null && novosPosts.isNotEmpty) {
        final postsCopy = posts.toList()..addAll(novosPosts);
        posts = postsCopy;
        currentPage++;
        if (novosPosts.length < 20) {
          finalPage = true;
        }
      } else if (novosPosts == null || novosPosts.isEmpty) {
        finalPage = true;
      }
    });
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

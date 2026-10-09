import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/HomePage.dart';
import 'package:myapp/Post.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/VisualizaPostPage.dart';

import 'UserPage.dart';

class PostsCurtidosPage extends StatefulWidget {
  const PostsCurtidosPage({super.key});

  @override
  State<PostsCurtidosPage> createState() => _PostsCurtidosPageState();
}

class _PostsCurtidosPageState extends State<PostsCurtidosPage> {
  List<Post> posts = [];
  bool loading = true;
  bool silentLoading = false;
  int currentPage = 0;
  bool finalPage = false;
  StreamSubscription<Post>? _postUpdatedSubscription;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshPosts(context);
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
        listPostsSilently(context);
      }
    });

    _postUpdatedSubscription = PostsRepository.onPostUpdated.listen((
      updatedPost,
    ) {
      if (!mounted) return;
      setState(() {
        final index = posts.indexWhere((p) => p.id == updatedPost.id);
        if (index != -1) {
          if (!updatedPost.curtidoPorMim) {
            posts.removeAt(index);
          } else {
            posts[index] = updatedPost;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _postUpdatedSubscription?.cancel();
    scrollController.dispose();
    super.dispose();
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
      novosPosts = await PostsRepository.buscaPostsCurtidos(null);
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
      novosPosts = await PostsRepository.buscaPostsCurtidos(
        posts.last.createdAt,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts Curtidos'), centerTitle: true),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => refreshPosts(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Você ainda não curtiu nenhum post.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: Colors.white,
            backgroundColor: Colors.blue,
            onRefresh: () => refreshPosts(context),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: posts.length + (silentLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final post = posts[index];
                return PostCardWidget(
                  post,
                  navega: () async {
                    final updatedPost = await Navigator.of(context).push<Post>(
                      MaterialPageRoute(
                        builder: (context) => VisualizaPostPage(post: post),
                      ),
                    );
                    if (updatedPost != null && mounted) {
                      final idx = posts.indexWhere(
                        (p) => p.id == updatedPost.id,
                      );
                      if (idx != -1) {
                        setState(() {
                          if (!updatedPost.curtidoPorMim) {
                            posts.removeAt(idx);
                          } else {
                            posts[idx] = updatedPost;
                          }
                        });
                      }
                    }
                  },onProfileTouch: (profile)=>
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (contenxt) =>
                            UserPage(user: profile),
                      ),
                    )
                );
              },
            ),
          );
        },
      ),
    );
  }
}

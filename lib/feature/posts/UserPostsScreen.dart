import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/data/Usuario.dart';
import 'package:myapp/data/repository/AuthRepository.dart';
import 'package:myapp/feature/posts/PostsHomeScreen.dart';
import 'package:myapp/feature/startup/LoginScreen.dart';

import '../../consts/Consts.dart';
import '../../data/Post.dart';
import '../../data/repository/PostsRepository.dart';
import 'PostDetailsScreen.dart';

class UserPostsScreen extends StatefulWidget {
  final Usuario user;

  const UserPostsScreen({super.key, required this.user});

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
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
    _streamSubscription = PostsRepository.onPostUpdated.listen((
      Post updatedPost,
    ) {
      if (!mounted) return;
      final index = posts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        setState(() {
          var _posts = List.of(posts);
          _posts[index] = updatedPost;
          posts = _posts;
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
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
      novosPosts = await PostsRepository.buscaPosts(
        null,
        widget.user.usuarioId,
      );
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
      novosPosts = await PostsRepository.buscaPosts(
        posts.last.createdAt,
        widget.user.usuarioId,
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
    final dateTime = widget.user.createdAt;
    final day = "${dateTime.day}".padLeft(2, '0');
    final month = "${dateTime.month}".padLeft(2, '0');
    final year = "${dateTime.year}";
    return Scaffold(
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(title: Text("Meu perfil")),
          SliverToBoxAdapter(child: Center(child: _userInfo(day, month, year))),
          if (loading)
            SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(childCount: posts.length, (
              context,
              index,
            ) {
              final post = posts[index];
              return Padding(
                padding: const EdgeInsets.all(12),
                child: PostCardWidget(
                  post,
                  navega: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailsScreen(post: post),
                    ),
                  ),
                  onProfileTouch: (profile) {
                    if (profile.usuarioId == widget.user.usuarioId) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (contenxt) => UserPostsScreen(user: profile),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          if (silentLoading)
            SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _userInfo(String day, String month, String year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Stack(
            children: [
              UserIconWidget(
                url: widget.user.urlAvatar?.replaceAll("s96-c", "s400-c") ?? "",
                size: Size(200, 200),
                borderRadius: 100,
                onTap: (_) {},
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton(
                  style: IconButton.styleFrom(
                    minimumSize: Size(60, 60),
                    backgroundColor: Colors.red[100],
                  ),
                  onPressed: () => showConfirmLogout(),
                  icon: Icon(Icons.logout, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            widget.user.fullName,
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[900],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card.filled(
            color: Colors.grey[200],
            margin: EdgeInsetsGeometry.all(0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.email_outlined),
                      Text(widget.user.email!, style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.account_circle_outlined),
                      Text(
                        "Cadastro em $day/$month/$year",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showConfirmLogout() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsetsGeometry.only(
            top: 32,
            bottom: 64,
            left: 16,
            right: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Center(
                child: Text(
                  "Tem certeza que deseja sair?",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(8),
                  ),
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  logout();
                },
                child: Text(
                  "Sair da minha conta",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void logout() async {
    try {
      await AuthRepository.logout();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => false);
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => LoginScreen()));
    } catch (e, trace) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ocorreu um erro!")));
    }
  }
}

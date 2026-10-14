import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/consts/Consts.dart';
import 'package:myapp/data/Post.dart';
import 'package:myapp/data/Usuario.dart';
import 'package:myapp/data/repository/PostsRepository.dart';
import 'package:myapp/feature/evidence/DisplayPictureScreen.dart';
import 'package:myapp/feature/evidence/DisplayVideoScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class PostCardWidget extends StatefulWidget {
  final Post post;
  final VoidCallback navega;
  final ValueChanged<Usuario> onProfileTouch;

  const PostCardWidget(
    this.post, {
    super.key,
    required this.navega,
    required this.onProfileTouch,
  });

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

    setState(() {
      curtido = novoCurtido;
      numCurtidas = novoNumCurtidas;
    });

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
          const SizedBox(height: 16),
          _userInfo(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tituloWidget(),
                const SizedBox(height: 4),
                _descricaoWidget(),
                const SizedBox(height: 8),
                _referenciaLocalizacaoWidget(),
                const SizedBox(height: 4),
              ],
            ),
          ),
          _postMedias(context),
          const SizedBox(height: 16),
          _postInteractionControls(),
        ],
      ),
    );
  }

  Text _descricaoWidget() {
    return Text(
      post.descricao,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 16, color: Colors.grey[900]),
    );
  }

  Text _tituloWidget() {
    return Text(
      post.titulo,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontSize: 18,
      ),
    );
  }

  Widget _referenciaLocalizacaoWidget() {
    return Card.filled(
      margin: EdgeInsets.zero,
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.place_outlined, color: Colors.grey[900]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${post.rua}${post.bairro.isNotEmpty ? ", Bairro ${post.bairro}" : ""}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                      fontSize: 16,
                    ),
                  ),
                  if (post.referenciaLocalizacao.isNotEmpty)
                    Text(
                      post.referenciaLocalizacao,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[900],
                        fontSize: 16,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () async {
                          launchUrl(
                            Uri.parse(
                              "geo:0,0?q=${post.lat},${post.lon}(${post.titulo})",
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postMedias(BuildContext context) {
    final midias = post.jsonMidias;
    if (midias.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: midias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          return FeedMediaItem(
            key: ValueKey("${midias[index].publicUrl}_$index"),
            midia: midias[index],
          );
        },
      ),
    );
  }

  Widget _postInteractionControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.navega,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(20),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            spacing: 12,
            children: [
              const Icon(Icons.comment_outlined, color: Colors.grey),
              Text(
                "$numComentarios",
                style: TextStyle(fontSize: 16, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _onLikeToggled,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(20),
            backgroundColor: Colors.transparent,
          ),
          child: Row(
            spacing: 12,
            children: [
              Icon(
                curtido ? Icons.favorite : Icons.favorite_border,
                color: curtido ? Colors.red : Colors.grey,
              ),
              Text(
                "$numCurtidas",
                style: TextStyle(fontSize: 16, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _userInfo() {
    return Row(
      children: [
        UserIconWidget(
          url: post.usuario.urlAvatar ?? "",
          onTap: (_) => widget.onProfileTouch(post.usuario),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.usuario.fullName,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              Text(
                "@${post.usuario.fullName.replaceAll(" ", "")}",
                style: const TextStyle(color: Colors.blue, fontSize: 12),
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
  bool _abrindo = false;

  String get mimeType => widget.midia.mime;
  Future<File>? _thumbFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mimeType.contains("image/")) {
      precacheImage(NetworkImage(url), context);
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
    const width = 200.0;
    const height = 200.0;
    return Builder(
      builder: (context) {
        if (mimeType.contains("image/")) {
          return _imageWidget(width, height);
        } else if (mimeType.contains("video/")) {
          return _videoWidget(width, height);
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

  Widget _videoWidget(double width, double height) {
    return FutureBuilder<File>(
      future: _thumbFuture,
      initialData: PostsRepository.thumbnailEmCache(widget.midia),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _mediaErrorWidget(width, height, context);
        }
        if (!snapshot.hasData) {
          return _mediaLoadingWidget(width, height);
        }
        return _mediaLoadedWidget(
          context,
          width,
          height,
          Stack(
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
          _abrirVideo,
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

  Widget _imageLoadedWidget(
    double width,
    double height,
    ImageProvider<Object> provider,
    BuildContext context,
  ) {
    return _mediaLoadedWidget(
      context,
      width,
      height,
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black12,
          image: DecorationImage(image: provider, fit: BoxFit.fitWidth),
        ),
      ),
      () {
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
  }

  ClipRRect _mediaLoadedWidget(
    BuildContext context,
    double width,
    double height,
    Widget child,
    VoidCallback onTapUp,
  ) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(14),
      child: Material(
        borderRadius: BorderRadiusGeometry.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTapUp: (_) {
            onTapUp();
          },
          child: Ink(
            width: width,
            height: height,
            decoration: BoxDecoration(color: Colors.grey[300]),
            child: child,
          ),
        ),
      ),
    );
  }

  Card _mediaLoadingWidget(double width, double height) {
    return Card(
      margin: const EdgeInsets.all(0),
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

  SizedBox _mediaErrorWidget(
    double width,
    double height,
    BuildContext context,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        color: Theme.of(context).colorScheme.error,
        child: const Center(child: Icon(Icons.video_camera_back_outlined)),
      ),
    );
  }

  Widget _imageWidget(double width, double height) {
    return CachedNetworkImage(
      fit: BoxFit.fill,
      imageUrl: url,
      imageBuilder: (context, provider) {
        return _imageLoadedWidget(width, height, provider, context);
      },
      placeholder: (context, url) {
        return _mediaLoadingWidget(width, height);
      },
      errorWidget: (context, url, error) {
        return _mediaErrorWidget(width, height, context);
      },
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
    required this.onTap,
    required this.url,
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
        placeholder: (context, url) => const Icon(Icons.account_circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _userImage();
  }
}

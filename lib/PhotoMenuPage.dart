import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:mime/mime.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/ImageThumbnailWidget.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/SeletorLocalizacao.dart';
import 'package:myapp/TirarFotoPage.dart';
import 'package:myapp/VideoThumbnailWidget.dart';
import 'package:uuid/uuid.dart';

import 'DisplayVideoScreen.dart';
import 'Post.dart';

class PhotoMenuPage extends StatefulWidget {
  final String postId;

  PhotoMenuPage({String? postId, super.key}) : postId = postId ?? Uuid().v4();

  @override
  State<PhotoMenuPage> createState() => _PhotoMenuPageState();
}

class _PhotoMenuPageState extends State<PhotoMenuPage> {
  ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<bool> canFinish = ValueNotifier(false);
  final ValueNotifier<Map<String, dynamic>?> jsonEndereco = ValueNotifier(null);
  final referenciaLocalizacaoController = TextEditingController();
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  ValueNotifier<List<XFile>> midiasPost = ValueNotifier(List.empty());

  void validaCampos() {
    final camposValidados =
        midiasPost.value.isNotEmpty &&
        tituloController.text.isNotEmpty &&
        descricaoController.text.isNotEmpty &&
        jsonEndereco.value != null;
    canFinish.value = camposValidados;
  }

  Post instanciaPost() {
    final jsonEndereco = this.jsonEndereco.value;
    return Post(
      id: widget.postId,
      titulo: tituloController.text,
      descricao: descricaoController.text,
      referenciaLocalizacao: referenciaLocalizacaoController.text,
      lon: jsonEndereco?['lon'],
      lat: jsonEndereco?['lat'],
      rua: jsonEndereco?['road'] ?? '',
      bairro:
          jsonEndereco?['suburb'] ??
          jsonEndereco?['neighbourhood'] ??
          jsonEndereco?['district'] ??
          '',
      cidade: jsonEndereco?['city'] ?? '',
      cep: jsonEndereco?['postcode'] ?? '',
      jsonEndereco: jsonEndereco.toString(),
      jsonMidias: [],
    );
  }

  @override
  void initState() {
    super.initState();
    midiasPost.value = PostsRepository.midiasPost;
    tituloController.addListener(() {
      validaCampos();
    });
    descricaoController.addListener(() {
      validaCampos();
    });
    usaLocalizacaoAtual();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Criar uma publicação")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
              child: Material(child: formWidget(context)),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: loading,
            builder: (context, value, child) {
              if (value) {
                return SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(color: Colors.black12),
                      CircularProgressIndicator(),
                    ],
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Column formWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder(
          valueListenable: midiasPost,
          builder: (context, value, child) {
            return mediaListControls(value);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              minLines: null,
              maxLength: 200,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Título do post",
              ),
              controller: tituloController,
            ),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              maxLength: 1000,
              maxLines: null,
              minLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Descrição detalhada",
              ),
              controller: descricaoController,
            ),
          ],
        ),
        Text("Localização"),
        locationControls(context),
        ValueListenableBuilder(
          valueListenable: jsonEndereco,
          builder: (context, value, child) {
            if (value == null) {
              return Text("Buscando seu local atual...");
            }
            final jsonEndereco = value;
            return Text(
              "${jsonEndereco['postcode']}, ${jsonEndereco['road']}, ${jsonEndereco['suburb'] ?? jsonEndereco['neighbourhood'] ?? jsonEndereco['district']}, ${jsonEndereco['city']}",
            );
          },
        ),
        TextField(
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          minLines: null,
          maxLength: 200,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Referência do local",
          ),
          controller: referenciaLocalizacaoController,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ValueListenableBuilder(
              valueListenable: canFinish,
              builder: (context, value, child) {
                return FilledButton.tonal(
                  style: value
                      ? FilledButton.styleFrom()
                      : FilledButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                        ),
                  onPressed: value ? () => publicaPost(context) : null,
                  child: Row(
                    children: [
                      Text("Publicar"),
                      SizedBox(width: 8),
                      Icon(Icons.send),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Row locationControls(BuildContext context) {
    return Row(
      children: [
        FilledButton(
          onPressed: () {
            usaLocalizacaoAtual();
          },
          child: Row(children: [Icon(Icons.location_on), Text("Local atual")]),
        ),
        FilledButton(
          onPressed: () async {
            loading.value = true;
            final currentLocation = await LocationService.getCurrentPosition();
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SeletorLocalizacao(
                  latLong: currentLocation,
                  onPicked: (PickedData pickedData) {
                    setaJsonEndereco(pickedData);
                  },
                ),
              ),
            );
            loading.value = false;
          },
          child: Row(
            children: [Icon(Icons.my_location), Text("Selecionar no mapa")],
          ),
        ),
      ],
    );
  }

  void setaJsonEndereco(PickedData pickedData) {
    final addressData = pickedData.addressData;
    addressData['lat'] = pickedData.latLong.latitude;
    addressData['lon'] = pickedData.latLong.longitude;
    jsonEndereco.value = pickedData.addressData;
  }

  void usaLocalizacaoAtual() {
    _usaLocalizacaoAtual();
  }

  Future<void> _usaLocalizacaoAtual() async {
    final currentLocation = await LocationService.getCurrentPosition();
    final geocodingService = GeocodingService(
      nominatimHost: 'nominatim.openstreetmap.org',
      language: 'pt',
      userAgent: 'InfraSantaCruz/1.0',
    );
    setaJsonEndereco(await geocodingService.reverseGeocode(currentLocation));
  }

  Future<void> publicaPost(BuildContext context) async {
    loading.value = true;
    try {
      await PostsRepository.criaPost(instanciaPost());
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Consts.POST_SUCCESS)));
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(Consts.ERROR)));
      loading.value = false;
    }
  }

  void pickSingleFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String path = result.files.single.path!;
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DisplayPictureScreen(imagePath: path);
            },
          ),
        );
      }
    }
  }

  void confirmacaoDeletar(BuildContext context, XFile file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Deletar mídia?"),
          content: Text("Você não poderá reverter"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                PostsRepository.deletaMidia(file);
                midiasPost.value = PostsRepository.midiasPost.toList();
                Navigator.of(context).pop();
              },
              child: Text("Deletar"),
            ),
          ],
        );
      },
    );
  }

  Widget mediaListControls(List<XFile> midias) {
    return Column(
      children: [
        Text("Fotos e evidências"),
        MediaListWidget(
          mediaFiles: midias,
          onDelete: (file) => confirmacaoDeletar(context, file),
        ),
        Row(
          children: [
            FilledButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TirarFotoPage()),
                );
                midiasPost.value = PostsRepository.midiasPost.toList();
                validaCampos();
              },
              child: Row(
                children: [
                  Icon(Icons.photo_camera_front_outlined),
                  Text("Capturar"),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => pickSingleFile(context),
              child: Row(children: [Icon(Icons.attach_file), Text("Anexar")]),
            ),
          ],
        ),
      ],
    );
  }
}

class MediaListWidget extends StatelessWidget {
  final List<XFile> mediaFiles;

  final void Function(XFile file) onDelete;

  const MediaListWidget({
    super.key,
    required this.mediaFiles,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final parentHeight = 200.0;
    return SizedBox(
      height: mediaFiles.isEmpty ? 0 : parentHeight,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: mediaFiles.length,
        itemBuilder: ((context, index) {
          final file = mediaFiles[index];
          final mimeType = lookupMimeType(file.path);
          return mediaThumbnail(mimeType, file, context);
        }),
        separatorBuilder: ((context, index) {
          return SizedBox(width: 10);
        }),
      ),
    );
  }

  Widget mediaThumbnail(String? mimeType, XFile file, BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Builder(
              builder: (context) {
                if (mimeType?.contains("image") == true) {
                  return imageThumbnail(file, context);
                } else if (mimeType?.contains("video") == true) {
                  return videoThumbnail(file, context);
                } else {
                  return Container(color: Colors.grey);
                }
              },
            ),
          ),
          deleteButton(file),
        ],
      ),
    );
  }

  Align deleteButton(XFile file) {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton.filledTonal(
        onPressed: () {
          onDelete(file);
        },
        icon: Icon(Icons.delete),
      ),
    );
  }

  Center videoThumbnail(XFile file, BuildContext context) {
    return Center(
      child: VideoThumbnailWidget(
        file: file,
        onTap: (file) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisplayVideoScreen(imagePath: file.path),
            ),
          );
        },
      ),
    );
  }

  Center imageThumbnail(XFile file, BuildContext context) {
    return Center(
      child: ImageThumbnailWidget(
        file: file,
        onTap: (file) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DisplayPictureScreen(imagePath: file.path, readOnly: true),
            ),
          );
        },
      ),
    );
  }
}

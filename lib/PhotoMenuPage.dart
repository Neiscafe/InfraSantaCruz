import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:mime/mime.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/SeletorLocalizacao.dart';
import 'package:myapp/TirarFotoPage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import 'Post.dart';

class PhotoMenuPage extends StatefulWidget {
  final String postId;

  PhotoMenuPage({String? postId, super.key}) : postId = postId ?? Uuid().v4();

  @override
  State<PhotoMenuPage> createState() => _PhotoMenuPageState();
}

class _PhotoMenuPageState extends State<PhotoMenuPage> {
  bool _loading = false;
  bool _canFinish = false;
  String title = "";
  String description = "";
  String referenciaLocalizacao = "";
  double? lon;
  double? lat;
  String labelLocalizacao = "";
  Map<String, dynamic>? jsonEndereco;
  List<XFile> medias = [];

  void _updateValues({
    String? titulo,
    String? descricao,
    double? lon,
    double? lat,
    Map<String, dynamic>? jsonEndereco,
  }) {
    titulo != null ? this.title = titulo : null;
    descricao != null ? this.description = descricao : null;
    lon != null ? this.lon = lon : null;
    lat != null ? this.lat = lat : null;
    if (jsonEndereco != null) {
      this.jsonEndereco = jsonEndereco;
      labelLocalizacao =
          "${jsonEndereco['postcode']}, ${jsonEndereco['road']}, ${jsonEndereco['suburb'] ?? jsonEndereco['neighbourhood'] ?? jsonEndereco['district']}, ${jsonEndereco['city']} ";
    }
    validaCampos();
  }

  void validaCampos() {
    final camposValidados =
        medias.isNotEmpty &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        lon != null &&
        lat != null &&
        jsonEndereco != null;
    setState(() {
      _canFinish = camposValidados;
    });
  }

  Post instanciaPost() {
    return Post(
      id: widget.postId,
      titulo: title,
      descricao: description,
      referenciaLocalizacao: referenciaLocalizacao,
      lon: lon!,
      lat: lat!,
      rua: jsonEndereco?['road'] ?? '',
      bairro:
          jsonEndereco?['suburb'] ??
          jsonEndereco?['neighbourhood'] ??
          jsonEndereco?['district'] ??
          '',
      cidade: jsonEndereco?['city'] ?? '',
      cep: jsonEndereco?['postcode'] ?? '',
      jsonEndereco: jsonEndereco.toString(),
    );
  }

  @override
  void initState() {
    super.initState();
    usaLocalizacaoAtual();
  }

  @override
  Widget build(BuildContext context) {
    medias = PostsRepository.ongoingPostImages;
    return Scaffold(
      appBar: AppBar(title: Text("Criar uma publicação")),
      floatingActionButton: buildFloatingActionButton(context),
      body: Material(
        child: Expanded(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fotos e evidências"),
                  lazyImageList(context, medias),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TirarFotoPage(),
                            ),
                          );
                        },
                        child: Text("Tirar foto"),
                      ),
                      TextButton(
                        onPressed: () => pickSingleFile(context),
                        child: Text("Anexar"),
                      ),
                    ],
                  ),

                  TextField(
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: null,
                    maxLength: 200,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Título do post",
                    ),
                    onChanged: (text) {
                      _updateValues(titulo: text);
                    },
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
                    onChanged: (text) {
                      _updateValues(descricao: text);
                    },
                  ),
                  Text("Localização"),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () {
                          usaLocalizacaoAtual();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.location_on),
                            Text("Local atual"),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          final currentLocation =
                              await LocationService.getCurrentPosition();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeletorLocalizacao(
                                latLong: currentLocation,
                                onPicked: (PickedData pickedData) {
                                  _updateValues(
                                    jsonEndereco: pickedData.addressData,
                                    lon: pickedData.latLong.longitude,
                                    lat: pickedData.latLong.latitude,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.my_location),
                            Text("Selecionar no mapa"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(this.labelLocalizacao),
                  TextField(
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: null,
                    maxLength: 200,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Referência do local",
                    ),
                    onChanged: (text) {
                      referenciaLocalizacao = text;
                    },
                  ),
                ],
              ),
              if (_loading) Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  void usaLocalizacaoAtual() async {
    final currentLocation = await LocationService.getCurrentPosition();
    final geocodingService = GeocodingService(
      nominatimHost: 'nominatim.openstreetmap.org',
      language: 'pt',
      userAgent: 'InfraSantaCruz/1.0',
    );
    final reverseGeocode = await geocodingService.reverseGeocode(
      currentLocation,
    );
    _updateValues(
      lon: currentLocation.longitude,
      lat: currentLocation.latitude,
      jsonEndereco: reverseGeocode.addressData,
    );
  }

  FloatingActionButton buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: _canFinish
          ? () {
              PostsRepository.criaPost(instanciaPost()).then((result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ? Consts.POST_SUCCESS : Consts.ERROR),
                  ),
                );
                result ? Navigator.pop(context) : null;
              });
              setState(() {
                _loading = true;
              });
            }
          : null,
      child: Text("Publicar"),
    );
  }

  Widget lazyImageList<T>(BuildContext context, List<XFile> images) {
    return SizedBox(
      height: medias.isEmpty ? 0 : 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: images.map((image) => lazyImageWidget(image)).toList(),
      ),
    );
  }

  Widget lazyImageWidget(XFile file) {
    // final future = Supabase.instance.client.storage
    //     .from('posts')
    //     .download('/$postId/${imagem.name}');
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        final mimeType = lookupMimeType(file.path);
        Widget child;
        if (snapshot.hasData) {
          try {
            if (mimeType?.contains("image") == true) {
              child = Image.memory(snapshot.data!);
            } else if (mimeType?.contains("video") == true) {
              child = VideoPlayer(VideoPlayerController.file(File(file.path)));
            } else {
              child = Container(color: Colors.grey);
            }
          } catch (e) {
            child = Center(child: Text('Vídeo'));
          }
        } else if (snapshot.hasError) {
          child = Text(snapshot.error.toString() + file.name);
        } else {
          child = CircularProgressIndicator();
        }
        return Card(
          child: Center(child: SizedBox(width: 70, height: 70, child: child)),
        );
      },
    );
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
}

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  String location = "";
  double? lon;
  double? lat;
  List<XFile> medias = [];

  void _updateValues({
    String? title,
    String? description,
    String? location,
    double? lon,
    double? lat,
  }) {
    title != null ? this.title = title : null;
    description != null ? this.description = description : null;
    location != null ? this.location = location : null;
    lon != null ? this.lon = lon : null;
    lat != null ? this.lat = lat : null;
    validaCampos();
  }

  void validaCampos() {
    final camposValidados =
        medias.isNotEmpty &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        lon != null &&
        lat != null;
    setState(() {
      _canFinish = camposValidados;
    });
  }

  Post instanciaPost() {
    return Post(
      id: widget.postId,
      title: title,
      description: description,
      location: location,
      lon: lon!,
      lat: lat!,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  StreamBuilder(
                    stream: Stream.value(PostsRepository.ongoingPostImages),
                    builder: (context, snapshot) =>
                        lazyImageList(context, snapshot.data ?? List.empty()),
                  ),

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
                  ),
                  Text("Localização"),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          final position = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.best,
                            ),
                          );
                          final placemarks = await placemarkFromCoordinates(
                            position.latitude,
                            position.longitude,
                          );
                          if (placemarks.isEmpty) {
                            _updateValues(
                              lon: position.longitude,
                              lat: position.latitude,
                              location: "Local desconhecido",
                            );
                          } else {
                            final place = placemarks[0];
                            _updateValues(
                              lon: position.longitude,
                              lat: position.latitude,
                              location:
                                  "${place.street} ${place.subLocality} ${place.name}, ${place.postalCode}",
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Icon(Icons.location_on),
                            Text("Local atual"),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeletorLocalizacao(
                                onPicked: (PickedData pickedData) {
                                  _updateValues(
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
                  Text(location),
                ],
              ),
              if (_loading) Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
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
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          height: size.width / 2,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: images.map((image) => lazyImageWidget(image)).toList(),
          ),
        ),
      ],
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

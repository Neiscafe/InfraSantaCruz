import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart' hide ImageFormat;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:mime/mime.dart';
import 'package:myapp/AuthRepository.dart';
import 'package:myapp/Consts.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/EnderecoGeocode.dart';
import 'package:myapp/PostsRepository.dart';
import 'package:myapp/SeletorLocalizacao.dart';
import 'package:myapp/TirarFotoPage.dart';
import 'package:myapp/VideoThumbnailWidget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'DisplayVideoScreen.dart';
import 'Post.dart';

class PhotoMenuPage extends StatefulWidget {
  final String? postId;

  const PhotoMenuPage({this.postId, super.key});

  @override
  State<PhotoMenuPage> createState() => _PhotoMenuPageState();
}

class _PhotoMenuPageState extends State<PhotoMenuPage> {
  ValueNotifier<bool> loading = ValueNotifier(false);
  late StreamSubscription<List<XFile>> _fileStreamSubscription;
  final ValueNotifier<bool> canFinish = ValueNotifier(false);
  final ValueNotifier<EnderecoGeocode?> enderecoGeocode = ValueNotifier(null);
  final referenciaLocalizacaoController = TextEditingController();
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  ValueNotifier<List<XFile>> _midiasPost = ValueNotifier(List.empty());

  void validaCampos() {
    final camposValidados =
        _midiasPost.value.isNotEmpty &&
        tituloController.text.isNotEmpty &&
        descricaoController.text.isNotEmpty &&
        enderecoGeocode.value != null;
    canFinish.value = camposValidados;
  }

  Post instanciaPost() {
    final enderecoGeocode = this.enderecoGeocode.value!;
    return Post(
      id: Uuid().v4(),
      titulo: tituloController.text,
      descricao: descricaoController.text,
      referenciaLocalizacao: referenciaLocalizacaoController.text,
      lon: enderecoGeocode.lon,
      lat: enderecoGeocode.lat,
      rua: enderecoGeocode.logradouro,
      bairro: enderecoGeocode.bairro,
      cidade: enderecoGeocode.cidade,
      cep: enderecoGeocode.cep,
      jsonEndereco: jsonEncode(enderecoGeocode.fullJson),
      jsonMidias: [],
      createdAt: '',
      usuario: AuthRepository.usuarioAtual,
    );
  }

  @override
  void initState() {
    super.initState();
    _fileStreamSubscription = PostsRepository.midiasPostStream.listen((list) {
      _midiasPost.value = list;
      validaCampos();
    });
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
    referenciaLocalizacaoController.dispose();
    _fileStreamSubscription.cancel();
    PostsRepository.limpaImagens();
    super.dispose();
  }

  Widget _evidenciasControls(List<XFile> value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fotos e evidências",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),

        MediaListWidget(
          mediaFiles: value,
          onAdd: () => exibeDialogInserirEvidencias(context),
          onDelete: (file) async {
            PostsRepository.removeImagem(file);
          },
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: () => exibeDialogInserirEvidencias(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.grey[200],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 25),
              Text("Adicionar evidências", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _tituloFormField() {
    return [
      Text("Título", style: TextStyle(color: Colors.black, fontSize: 16)),
      TextField(
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        minLines: null,
        maxLength: 200,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Ex: Buraco perigoso na via",
        ),
        controller: tituloController,
      ),
    ];
  }

  List<Widget> _descricaoFormField() {
    return [
      Text("Descrição", style: TextStyle(color: Colors.black, fontSize: 16)),
      TextField(
        textCapitalization: TextCapitalization.sentences,
        maxLength: 1000,
        maxLines: null,
        minLines: null,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Descreva o problema com o máximo de detalhes...",
        ),
        controller: descricaoController,
      ),
    ];
  }

  List<Widget> _referenciaFormField() {
    return [
      Text(
        "Como encontrar",
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      TextField(
        textCapitalization: TextCapitalization.sentences,
        maxLines: null,
        minLines: null,
        maxLength: 200,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Ex: Passando a faixa de segurança, bem no meio da via.",
        ),
        controller: referenciaLocalizacaoController,
      ),
    ];
  }

  Widget botaoFinalizar(bool habilitado) {
    return FilledButton.tonal(
      style: habilitado
          ? FilledButton.styleFrom()
          : FilledButton.styleFrom(
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
      onPressed: habilitado ? () => publicaPost(context) : null,
      child: Row(
        children: [Text("Publicar"), SizedBox(width: 8), Icon(Icons.send)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Criar uma publicação")),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _midiasPost,
                      builder: (context, value, child) {
                        return _evidenciasControls(value);
                      },
                    ),
                    SizedBox(height: 16),
                    ..._tituloFormField(),
                    SizedBox(height: 8),
                    ..._descricaoFormField(),
                    SizedBox(height: 8),
                    Text(
                      "Localização",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    ValueListenableBuilder(
                      valueListenable: enderecoGeocode,
                      builder: (context, endereco, child) {
                        return _localizacaoControls(endereco, context);
                      },
                    ),
                    SizedBox(height: 8),
                    ..._referenciaFormField(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: canFinish,
                          builder: (context, habilitado, child) {
                            return botaoFinalizar(habilitado);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  Widget _localizacaoControls(EnderecoGeocode? endereco, BuildContext context) {
    if (endereco == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [SizedBox(height: 8), _loadingLocalizacao()],
      );
    }
    return _cardLocalizacao(endereco);
  }

  Card _loadingLocalizacao() {
    return Card.filled(
      color: Colors.grey[200],
      margin: EdgeInsetsGeometry.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 4,
          children: [
            Icon(Icons.not_listed_location_outlined, size: 25),
            Text(
              "Determinando sua localização...",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardLocalizacao(EnderecoGeocode endereco) {
    return Column(
      children: [
        Card.filled(
          color: Colors.grey[200],
          margin: EdgeInsetsGeometry.all(0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 25, color: Colors.red),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "No. ${endereco.numero}\n${endereco.logradouro}",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          Text(endereco.bairro),
                          Text(endereco.cidade),
                        ],
                      ),
                    ],
                  ),
                ),
                MapMiniature(endereco: endereco),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () => exibeDialogLocalizacao(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.grey[200],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Icon(Icons.location_on_outlined, size: 25),
              Text("Selecionar outro local", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  void exibeDialogLocalizacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsetsGeometry.only(
            top: 32,
            bottom: 32,
            left: 16,
            right: 16,
          ),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(16),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  usaLocalizacaoAtual();
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(Icons.my_location, color: Colors.black, size: 30),
                    Text(
                      "Usar local atual",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(16),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  abreMapaLocalizacao();
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(
                      Icons.pin_drop_outlined,
                      color: Colors.black,
                      size: 30,
                    ),
                    Text(
                      "Selecionar no mapa",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void abreMapaLocalizacao() async {
    while (!(await Permission.location.isGranted)) {
      await Permission.location.request();
    }
    try {
      final enderecoGeocode = this.enderecoGeocode.value!;
      final currentLocation = LatLong(enderecoGeocode.lat, enderecoGeocode.lon);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeletorLocalizacao(
            latLong: currentLocation,
            onPicked: (Placemark pickedData, LatLong latLong) {
              setaEndereco(pickedData, latLong);
            },
          ),
        ),
      );
    } on Exception catch (e, trace) {
      debugPrint(e.toString());
      debugPrint(trace.toString());
    }
  }

  void exibeDialogInserirEvidencias(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsetsGeometry.only(
            top: 32,
            bottom: 32,
            left: 16,
            right: 16,
          ),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(16),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => TirarFotoPage()),
                  );
                },
                child: Row(
                  spacing: 8,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.black, size: 30),
                    Text(
                      "Tirar foto/vídeo",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(16),
                  ),
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: () {
                  Navigator.pop(context);
                  pickSingleFile();
                },
                child: Row(
                  spacing: 4,
                  children: [
                    Icon(Icons.photo, color: Colors.black, size: 30),
                    Text(
                      "Anexar da galeria",
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void setaEndereco(Placemark placemark, LatLong currentLocation) {
    enderecoGeocode.value = EnderecoGeocode.fromJson(
      placemark.toJson(),
      currentLocation,
    );
    validaCampos();
  }

  void usaLocalizacaoAtual() async {
    while (!(await Permission.location.isGranted)) {
      await Permission.location.request();
    }
    final currentLocation = await LocationService.getCurrentPosition();
    final res = await placemarkFromCoordinates(
      currentLocation.latitude,
      currentLocation.longitude,
    );
    setaEndereco(res.first, currentLocation);
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

  void pickSingleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        "jpeg",
        "png",
        "jpg",
        "mp4",
        "mov",
        "heic",
        "webp",
        "heif",
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        PostsRepository.adicionaMidia(file.xFile);
      }
    }
  }
}

class MapMiniature extends StatelessWidget {
  final EnderecoGeocode endereco;

  const MapMiniature({super.key, required this.endereco});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 140,
          width: 140,
          child: FlutterLocationPicker.withConfiguration(
            key: ValueKey('${endereco.lat}_${endereco.lon}'),
            searchConfiguration: SearchConfiguration(showSearchBar: false),
            initPosition: LatLong(endereco.lat, endereco.lon),
            showCurrentLocationPointer: false,
            markerConfiguration: MarkerConfiguration(
              markerIconOffset: 0,
              showMarkerShadow: true,
              markerIcon: Icon(Icons.location_on, size: 40, color: Colors.red),
            ),
            mapConfiguration: MapConfiguration(
              urlTemplate:
                  'https://api.maptiler.com/maps/hybrid-v4/{z}/{x}/{y}@2x.jpg?key=nwyFws2BC5ir8yBm0eKA',
              mapLanguage: 'pt',
              mapLoadingBackgroundColor: Colors.lightGreen,
            ),
            onPicked: (_) {},
            userAgent: "InfraSantaCruz/1.0 (guilhermeneis132@gmail.com)",
          ),
        ),
      ),
    );
  }
}

class MediaListWidget extends StatelessWidget {
  final List<XFile> mediaFiles;
  final ValueChanged<XFile> onDelete;
  final VoidCallback onAdd;

  const MediaListWidget({
    super.key,
    required this.mediaFiles,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final parentHeight = 80.0;
    return SizedBox(
      height: mediaFiles.isEmpty ? 0 : parentHeight,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: mediaFiles.length,
        itemBuilder: ((context, index) {
          final file = mediaFiles[index];
          final mimeType = lookupMimeType(file.path);
          if (mimeType?.contains("image/") == true) {
            return thumbnail(
              width: 80,
              height: 80,
              onLongPress: () => exibeDialogDeletar(context, file),
              onTapUp: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(
                      imagePath: file.path,
                      readOnly: true,
                    ),
                  ),
                );
              },
              child: Image(
                image: FileImage(File(file.path)),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox.expand(
                    child: Container(
                      color: Colors.grey[200],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                },
              ),
            );
          } else if (mimeType?.contains("video/") == true) {
            return thumbnail(
              width: 80,
              height: 80,
              onLongPress: () => exibeDialogDeletar(context, file),
              onTapUp: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return DisplayVideoScreen(
                        imagePath: file.path,
                        readOnly: true,
                      );
                    },
                  ),
                );
              },
              child: FutureBuilder(
                future: VideoThumbnail.thumbnailData(
                  video: file.path,
                  imageFormat: ImageFormat.JPEG,
                  maxWidth: 80,
                  quality: 75,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Stack(
                      children: [
                        SizedBox.expand(
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Center(child: Icon(Icons.play_circle)),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    PostsRepository.removeImagem(file);
                    return SizedBox.shrink();
                  } else {
                    return SizedBox.expand(
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                },
              ),
            );
          }
          return SizedBox.shrink();
        }),
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(width: 8);
        },
      ),
    );
  }

  void exibeDialogDeletar(BuildContext context, XFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32, top: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete(file);
                  },
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.delete, size: 30),
                      Text("Deletar", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget thumbnail({
    required int width,
    required int height,
    required VoidCallback onTapUp,
    required VoidCallback onLongPress,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(14),
      child: Material(
        borderRadius: BorderRadiusGeometry.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTapUp: (_) {
            onTapUp();
          },
          onLongPress: onLongPress,
          child: Ink(
            width: width.toDouble(),
            height: height.toDouble(),
            decoration: BoxDecoration(color: Colors.grey[300]),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget mediaThumbnail(String? mimeType, XFile file, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTapUp: (_) {
        if (mimeType?.contains("image") == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DisplayPictureScreen(imagePath: file.path, readOnly: true),
            ),
          );
        } else if (mimeType?.contains("video") == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DisplayVideoScreen(imagePath: file.path, readOnly: true),
            ),
          );
        }
      },
      onLongPress: () {
        exibeDialogDeletar(context, file);
      },
      child: Builder(
        builder: (context) {
          var child;
          if (mimeType?.contains("image") == true) {
            child = imageThumbnail(file, context);
          } else if (mimeType?.contains("video") == true) {
            child = Stack(
              children: [
                Positioned.fill(child: VideoThumbnailWidget(file: file)),
                Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle),
                ),
              ],
            );
          } else {
            child = Container(color: Colors.grey);
          }
          return ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(8),
            child: child,
          );
        },
      ),
    );
  }

  Widget imageThumbnail(XFile file, BuildContext context) {
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.expand(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Container(
          decoration: BoxDecoration(color: Colors.black),
          child: Image.memory(snapshot.data!),
        );
      },
    );
  }
}

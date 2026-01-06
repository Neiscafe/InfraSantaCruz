import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/DisplayVideoScreen.dart';
import 'package:myapp/main.dart';

class TirarFotoPage extends StatefulWidget {
  const TirarFotoPage({super.key});
  @override
  State<TirarFotoPage> createState() => _TirarFotoPageState();
}

class _TirarFotoPageState extends State<TirarFotoPage>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  bool _cameraStarted = false;
  XFile? _pendingFile;
  bool _gravando = false;

  void startCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await cameraController.initialize();
      if (!mounted) return;
      setState(() {
        _cameraStarted = true;
      });
    } catch (e) {
      print(e);
    }
  }

  void sendPendingFileIfExists() {
    if (_pendingFile == null) {
      return;
    }
    goToMediaReview(_pendingFile!);
  }

  void goToMediaReview(XFile file) {
    final mime = lookupMimeType(file.path);
    if (mime?.contains('image') == true) {
      Navigator.push(
        this.context,
        MaterialPageRoute(
          builder: (context) {
            return DisplayPictureScreen(imagePath: file.path);
          },
        ),
      );
    } else if (mime?.contains('video') == true) {
      Navigator.push(
        this.context,
        MaterialPageRoute(
          builder: (context) {
            return DisplayVideoScreen(imagePath: file.path);
          },
        ),
      );
    } else {}
  }

  void takePhoto(BuildContext context) async {
    cameraController.takePicture().then((file) {
      _pendingFile = file;
      if (!context.mounted) {
        return;
      }
      _pendingFile = null;
      goToMediaReview(file);
    });
  }

  void startRecording() {
    cameraController.startVideoRecording();
    setState(() {
      _gravando = true;
    });
  }

  void stopRecording(BuildContext context) async {
    cameraController.stopVideoRecording().then((file) {
      _pendingFile = file;
      if (!context.mounted) {
        return;
      }
      setState(() {
        _gravando = false;
      });
      _pendingFile = null;
      goToMediaReview(file);
    });
  }

  Widget cameraElement(BuildContext context) {
    if (_cameraStarted) {
      final size = MediaQuery.of(context).size;
      final IconData iconData;
      if (_gravando) {
        iconData = Icons.stop;
      } else {
        iconData = Icons.photo_camera;
      }
      return Stack(
        children: [
          Container(
            height: size.height,
            width: size.width,
            child: CameraPreview(cameraController),
          ),
          Material(
            borderRadius: BorderRadius.circular(50),
            elevation: 20,
            child: GestureDetector(
              onTap: () => takePhoto(context),
              onLongPress: () => startRecording(),
              onLongPressEnd: (_) => stopRecording(context),
              child: SizedBox(child: Icon(iconData), width: 200, height: 200),
            ),
          ),
        ],
      );
    } else {
      startCamera();
      return Center(child: Text("Carregando..."));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_gravando) {
        stopRecording(this.context);
      }
    } else if (state == AppLifecycleState.resumed) {
      sendPendingFileIfExists();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: cameraElement(context));
  }
}
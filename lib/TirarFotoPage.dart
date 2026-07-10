import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/DisplayVideoScreen.dart';

class TirarFotoPage extends StatefulWidget {
  const TirarFotoPage({super.key});

  @override
  State<TirarFotoPage> createState() => _TirarFotoPageState();
}

class _TirarFotoPageState extends State<TirarFotoPage>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? cameraController;
  int _selectedCameraIndex = 0;
  bool _cameraStarted = false;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  XFile? _pendingFile;
  bool _gravando = false;

  Widget cameraElement(BuildContext context) {
    double _ = MediaQuery.of(context).size.width;
    final Widget mainButton;
    final Widget recordButton;
    if (_gravando) {
      recordButton = Spacer();
      mainButton = FilledButton(
        style: FilledButton.styleFrom(minimumSize: Size.square(80)),
        onPressed: () => _stopRecording(context),
        child: Icon(Icons.stop),
      );
    } else {
      recordButton = FilledButton(
        style: FilledButton.styleFrom(minimumSize: Size.square(40)),
        onPressed: () => startRecording(),
        child: Icon(Icons.fiber_manual_record_rounded),
      );
      mainButton = FilledButton(
        style: FilledButton.styleFrom(minimumSize: Size.square(80)),
        onPressed: () => takePhoto(context),
        child: Icon(Icons.photo_camera),
      );
    }
    if (_cameraStarted) {
      final size = MediaQuery.of(context).size;
      return Stack(
        children: [
          SizedBox(
            height: size.height,
            width: size.width,
            child: Listener(
              onPointerDown: (_) => _pointers++,
              onPointerUp: (_) => _pointers--,
              child: CameraPreview(
                cameraController!,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onTapDown: (TapDownDetails details) {
                        onViewFinderTap(details, constraints);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: Size.square(40),
                          ),
                          onPressed: _changeOrientation,
                          child: Icon(Icons.cameraswitch_outlined),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [mainButton],
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [recordButton],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      startCamera();
      return Center(child: Text("Carregando..."));
    }
  }

  void _changeOrientation() async {
    if (cameras.length < 2) {
      return;
    }
    if (cameraController != null) {
      await cameraController!.dispose();
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    startCamera();
  }

  void startCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await cameraController?.initialize();
      _minAvailableZoom = await cameraController!.getMinZoomLevel();
      _maxAvailableZoom = await cameraController!.getMaxZoomLevel();
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
    cameraController?.takePicture().then((file) {
      _pendingFile = file;
      if (!context.mounted) {
        return;
      }
      _pendingFile = null;
      goToMediaReview(file);
    });
  }

  void startRecording() {
    cameraController?.startVideoRecording();
    setState(() {
      _gravando = true;
    });
  }

  void _stopRecording(BuildContext context) async {
    cameraController?.stopVideoRecording().then((file) {
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

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (this.cameraController == null) {
      return;
    }

    final CameraController cameraController = this.cameraController!;

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (cameraController == null || _pointers != 2) {
      return;
    }
    _currentScale = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );
    debugPrint("scale: ${details.scale} - currentScale: ${_currentScale}");

    await cameraController!.setZoomLevel(_currentScale);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_gravando) {
        _stopRecording(this.context);
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
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: cameraElement(context));
  }
}

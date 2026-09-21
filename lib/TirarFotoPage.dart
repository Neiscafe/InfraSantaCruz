import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ValueNotifier<bool> _flashOn = ValueNotifier(false);
  ValueNotifier<double> _currentScale = ValueNotifier(1.0);
  double _baseScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  XFile? _pendingFile;
  String erro = "";
  Timer? timer;
  final ValueNotifier<bool> _gravando = ValueNotifier(false);
  final ValueNotifier<int?> videoDurationNotifier = ValueNotifier(null);

  void startVideoTimer() {
    timer?.cancel();
    videoDurationNotifier.value = 0;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      videoDurationNotifier.value = (videoDurationNotifier.value ?? 0) + 1;
      if (videoDurationNotifier.value! > 60) {
        _stopRecording(this.context);
      }
    });
  }

  void stopVideoTimer() {
    timer?.cancel();
    videoDurationNotifier.value = null;
  }

  void _switchFlash() {
    _flashOn.value = !_flashOn.value;
    cameraController?.setFlashMode(
      _flashOn.value ? FlashMode.always : FlashMode.off,
    );
  }

  Widget cameraElement(BuildContext context) {
    if (_cameraStarted) {
      return Stack(
        children: [
          SizedBox.expand(child: Container(color: Colors.black)),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: _closeButton(context),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: ValueListenableBuilder(
                valueListenable: _flashOn,
                builder: (context, flashOn, child) {
                  return _flashButton(flashOn);
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Listener(
              onPointerDown: (_) => _pointers++,
              onPointerUp: (_) => _pointers--,
              child: _camera(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: ValueListenableBuilder(
                valueListenable: _currentScale,
                builder: (context, zoom, child) {
                  return _zoomMultiplier(zoom);
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValueListenableBuilder(
                    valueListenable: videoDurationNotifier,
                    builder: (context, value, child) {
                      if (value == null) {
                        return SizedBox.shrink();
                      }
                      return _videoDuration(value);
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: _gravando,
                    builder: (context, value, child) {
                      return _cameraControls(value, context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // startCamera();
      return Center(child: Text(erro));
    }
  }

  Widget _zoomMultiplier(double zoom) {
    if (zoom == 1) return SizedBox.shrink();
    return UnconstrainedBox(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          child: Text(
            "${zoom.toStringAsFixed(1)}x",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  ClipRRect _camera() {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(16),
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
    );
  }

  IconButton _flashButton(bool flashOn) {
    return IconButton(
      style: IconButton.styleFrom(foregroundColor: Colors.white, iconSize: 30),
      onPressed: _switchFlash,
      icon: Icon(flashOn ? Icons.flash_on : Icons.flash_off),
    );
  }

  IconButton _closeButton(BuildContext context) {
    return IconButton(
      style: IconButton.styleFrom(foregroundColor: Colors.white, iconSize: 30),
      onPressed: () => Navigator.pop(context),
      icon: Icon(Icons.close),
    );
  }

  UnconstrainedBox _videoDuration(int value) {
    return UnconstrainedBox(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          child: Text(
            "${(value / 60).toInt().toString().padLeft(2, '0')}:${(value % 60).toInt().toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Row _cameraControls(bool value, BuildContext context) {
    return Row(
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _changeOrientation,
                child: Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!value) ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size.square(80),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => takePhoto(context),
                child: Icon(Icons.photo_camera),
              ),
            ] else ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size.square(80),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _stopRecording(context),
                child: Icon(Icons.stop),
              ),
            ],
          ],
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!value) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: Size.square(40),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => startRecording(),
                  child: Icon(Icons.fiber_manual_record_rounded),
                ),
              ] else ...[
                Spacer(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _changeOrientation() async {
    if (cameras.length < 2) {
      return;
    }
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    await cameraController?.setDescription(cameras[_selectedCameraIndex]);
  }

  void startCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await cameraController?.initialize();
      await cameraController?.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
      await cameraController?.prepareForVideoRecording();
      _minAvailableZoom = await cameraController!.getMinZoomLevel();
      _maxAvailableZoom = await cameraController!.getMaxZoomLevel();
      if (!mounted) return;
      setState(() {
        _cameraStarted = true;
      });
    } catch (e) {
      setState(() {
        erro = e.toString();
      });
    }
  }

  void sendPendingFileIfExists() {
    if (_pendingFile == null) {
      return;
    }
    callback(_pendingFile!);
  }

  void callback(XFile file) {
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
    final takenPhoto = await cameraController?.takePicture();
    if (takenPhoto == null) {
      return;
    }
    _pendingFile = takenPhoto;
    if (!context.mounted) {
      return;
    }
    _pendingFile = null;
    callback(takenPhoto);
  }

  void startRecording() {
    cameraController?.startVideoRecording();
    _gravando.value = true;
    startVideoTimer();
  }

  void _stopRecording(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    _gravando.value = false;
    final file = await cameraController?.stopVideoRecording();
    stopVideoTimer();
    _pendingFile = file;
    if (!context.mounted) {
      return;
    }
    _pendingFile = null;
    callback(file!);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale.value;
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
    _currentScale.value = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );
    debugPrint(
      "scale: ${details.scale} - currentScale: ${_currentScale.value}",
    );

    await cameraController!.setZoomLevel(_currentScale.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_gravando.value) {
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
    startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: cameraElement(context));
  }
}

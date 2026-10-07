import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:myapp/DisplayPictureScreen.dart';
import 'package:myapp/DisplayVideoScreen.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class TirarFotoPage extends StatefulWidget {
  const TirarFotoPage({super.key});

  @override
  State<TirarFotoPage> createState() => _TirarFotoPageState();
}

class _TirarFotoPageState extends State<TirarFotoPage>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  late StreamSubscription<NativeDeviceOrientation> _orientationSubscription;
  CameraController? cameraController;
  int _selectedCameraIndex = 0;
  bool _cameraStarted = false;
  bool _flashOn = false;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  int _pointers = 0;
  XFile? _pendingFile;
  DeviceOrientation? _orientation;
  String erro = "";
  Timer? timer;
  bool _gravando = false;
  bool _stoppingRecording = false;
  int? _videoDurationValue;

  void startVideoTimer() {
    timer?.cancel();
    setState(() {
      _videoDurationValue = 0;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _videoDurationValue = (_videoDurationValue ?? 0) + 1;
        });
        if (_videoDurationValue! >= 60) {
          _stopRecording(context);
        }
      }
    });
  }

  void stopVideoTimer() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        _videoDurationValue = null;
      });
    }
  }

  void _switchFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    cameraController?.setFlashMode(_flashOn ? FlashMode.always : FlashMode.off);
  }

  Widget _cameraPreviewWidget() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final int quarterTurns;
    switch (_orientation) {
      case DeviceOrientation.landscapeRight:
        quarterTurns = 3;
        break;
      case DeviceOrientation.portraitDown:
        quarterTurns = 2;
        break;
      case DeviceOrientation.landscapeLeft:
        quarterTurns = 1;
        break;
      default:
        quarterTurns = 0;
        break;
    }

    return RotatedBox(
      quarterTurns: quarterTurns,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget cameraElement(BuildContext context) {
    if (!_cameraStarted || cameraController == null) {
      return Center(child: Text(erro));
    }
    return Stack(
      children: [
        SizedBox.expand(child: Container(color: Colors.black)),
        Center(
          child: Listener(
            onPointerDown: (_) => _pointers++,
            onPointerUp: (_) => _pointers--,
            child: _cameraPreviewWidget(),
          ),
        ),
        OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _closeButton(context),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _flashButton(_flashOn),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(top: isLandscape ? 16 : 80),
                      child: _zoomMultiplier(_currentScale),
                    ),
                  ),
                ),
                Align(
                  alignment: isLandscape
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(isLandscape ? 16 : 24),
                      child: isLandscape
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _videoDurationValue == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _videoDuration(
                                          _videoDurationValue!,
                                        ),
                                      ),
                                _cameraControlsLandscape(context),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _videoDurationValue == null
                                    ? const SizedBox.shrink()
                                    : Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _videoDuration(
                                          _videoDurationValue!,
                                        ),
                                      ),
                                _cameraControls(context),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _cameraControlsLandscape(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.square(44),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: _changeOrientation,
          child: const Icon(Icons.cameraswitch_outlined),
        ),
        const SizedBox(height: 12),
        if (!_gravando) ...[
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.square(64),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () => takePhoto(context),
            child: const Icon(Icons.photo_camera, size: 28),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.square(44),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: startRecording,
            child: const Icon(
              Icons.fiber_manual_record_rounded,
              color: Colors.red,
            ),
          ),
        ] else ...[
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.square(64),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () => _stopRecording(context),
            child: const Icon(Icons.stop, size: 28),
          ),
        ],
      ],
    );
  }

  Widget _zoomMultiplier(double zoom) {
    if (zoom == 1) return const SizedBox.shrink();
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
            style: const TextStyle(color: Colors.white),
          ),
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
      icon: const Icon(Icons.close),
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
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Row _cameraControls(BuildContext context) {
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
                  minimumSize: const Size.square(40),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _stoppingRecording ? null : _changeOrientation,
                child: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_gravando) ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.square(80),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => takePhoto(context),
                child: const Icon(Icons.photo_camera),
              ),
            ] else ...[
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.square(80),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: _stoppingRecording
                    ? null
                    : () => _stopRecording(context),
                child: _stoppingRecording
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.stop),
              ),
            ],
          ],
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_gravando) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.square(40),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: startRecording,
                  child: const Icon(
                    Icons.fiber_manual_record_rounded,
                    color: Colors.red,
                  ),
                ),
              ] else ...[
                const Spacer(),
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
    if (cameras.isEmpty) {
      if (mounted) setState(() => erro = "Nenhuma câmera encontrada");
      return;
    }
    cameraController = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await cameraController?.initialize();
      await cameraController?.unlockCaptureOrientation();
      await cameraController?.prepareForVideoRecording();
      _minAvailableZoom = await cameraController!.getMinZoomLevel();
      _maxAvailableZoom = await cameraController!.getMaxZoomLevel();
      if (!mounted) return;
      setState(() {
        _cameraStarted = true;
      });
    } catch (e) {
      if (!mounted) return;
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return DisplayPictureScreen(imagePath: file.path);
          },
        ),
      );
    } else if (mime?.contains('video') == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return DisplayVideoScreen(imagePath: file.path);
          },
        ),
      );
    }
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
    setState(() {
      _gravando = true;
    });
    startVideoTimer();
  }

  void _stopRecording(BuildContext context) async {
    if (_stoppingRecording || !context.mounted) {
      return;
    }
    setState(() {
      _stoppingRecording = true;
    });

    try {
      final file = await cameraController?.stopVideoRecording();
      stopVideoTimer();
      if (mounted) {
        setState(() {
          _gravando = false;
        });
      }

      if (file == null) return;
      _pendingFile = file;
      if (!context.mounted) return;
      _pendingFile = null;
      callback(file);
    } catch (e) {
      debugPrint("Erro ao parar gravação: $e");
    } finally {
      if (mounted) {
        setState(() {
          _stoppingRecording = false;
        });
      }
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (cameraController == null) {
      return;
    }

    final Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController!.setExposurePoint(offset);
    cameraController!.setFocusPoint(offset);
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (cameraController == null || _pointers != 2) {
      return;
    }
    final newScale = (_baseScale * details.scale).clamp(
      _minAvailableZoom,
      _maxAvailableZoom,
    );
    setState(() {
      _currentScale = newScale;
    });

    await cameraController!.setZoomLevel(_currentScale);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_gravando) {
        _stopRecording(context);
      }
    } else if (state == AppLifecycleState.resumed) {
      sendPendingFileIfExists();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    startCamera();
    _orientationSubscription = NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((NativeDeviceOrientation orientation) {
          if (!mounted || cameraController?.value.isInitialized != true) return;
          final deviceOrientation = _convertToDeviceOrientation(orientation);
          setState(() {
            _orientation = deviceOrientation;
          });
          cameraController?.lockCaptureOrientation(deviceOrientation);
        });
  }

  DeviceOrientation _convertToDeviceOrientation(
    NativeDeviceOrientation orientation,
  ) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case NativeDeviceOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      case NativeDeviceOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      case NativeDeviceOrientation.portraitUp:
      default:
        return DeviceOrientation.portraitUp;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    cameraController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _orientationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: cameraElement(context));
  }
}

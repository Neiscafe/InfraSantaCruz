import 'package:flutter/material.dart';
import 'package:myapp/TirarFotoPage.dart';
import 'package:myapp/main.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissaoCameraPage extends StatefulWidget {
  const PermissaoCameraPage({super.key});

  @override
  State<PermissaoCameraPage> createState() => _PermissaoCameraPageState();
}

class _PermissaoCameraPageState extends State<PermissaoCameraPage> {
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  void _openAppSettings() {
    openAppSettings();
  }

  Future<void> requestPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _permissionStatus = status;
      });
      return;
    }
    status = await Permission.microphone.request();
    setState(() {
      _permissionStatus = status;
    });
  }

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      Text('Permissão da câmera: $_permissionStatus'),
      const SizedBox(height: 20),
    ];
    if (_permissionStatus.isDenied) {
      children.add(
        ElevatedButton(
          onPressed: requestPermission,
          child: Text('Pedir permissão'),
        ),
      );
    } else if (_permissionStatus.isPermanentlyDenied) {
      children.add(
        Column(
          children: [
            const SizedBox(height: 20),
            const Text('Por favor, dê permissão para câmera'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _openAppSettings,
              child: Text('Abrir configurações'),
            ),
          ],
        ),
      );
    } else {
      children.add(
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TirarFotoPage()),
            );
          },
          child: Text('Prosseguir'),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:myapp/HomePage.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissaoPage extends StatefulWidget {
  @override
  _PermissaoPageState createState() => _PermissaoPageState();
}

class _PermissaoPageState extends State<PermissaoPage> {
  // Função para solicitar todas as permissões de uma vez
  Future<void> _requestPermissions() async {
    ServiceStatus serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Ligue o GPS"),
          content: Text(
            "O app precisa do GPS ligado para usar sua localização em tempo real.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => {}, // Abre a tela de ajustes do celular
              child: Text("Ligar"),
            ),
          ],
        ),
      );
      return;
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      // Nota: No permission_handler, Vídeo é coberto por Camera + Microfone
    ].request();

    // Verifica se todas foram aceitas
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todas as permissões concedidas!")),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
    } else {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permissões Necessárias"),
        content: Text(
          "O app precisa dessas permissões para funcionar. Deseja ir nas configurações habilitar manualmente?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            // Abre a tela de ajustes do celular
            child: Text("Configurações"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(30),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 100, color: Colors.blue),
            SizedBox(height: 30),
            Text(
              "Precisamos de acesso",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              "Para uma experiência completa, precisamos de acesso ao seu GPS, Câmera e Microfone.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 40),
            _buildPermissionItem(
              Icons.location_on,
              "Localização",
              "Para ver posts próximos",
            ),
            _buildPermissionItem(
              Icons.camera_alt,
              "Câmera e Vídeo",
              "Para registrar momentos",
            ),
            _buildPermissionItem(Icons.mic, "Áudio", "Para capturar som"),
            Spacer(),
            ElevatedButton(
              onPressed: _requestPermissions,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("CONCEDER PERMISSÕES"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: CircleAvatar(child: Icon(icon, size: 20)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

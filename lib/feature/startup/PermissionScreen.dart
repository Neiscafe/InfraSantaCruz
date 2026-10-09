import 'package:flutter/material.dart';
import 'package:myapp/feature/posts/PostsHomeScreen.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> pedePermissoes(BuildContext context) async {
    ServiceStatus serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      if (!context.mounted) return;
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
            TextButton(onPressed: () => {}, child: Text("Ligar")),
          ],
        ),
      );
      return;
    }
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!context.mounted) return;
    if (allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todas as permissões concedidas!")),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => PostsHomeScreen()));
    } else {
      erroPermissoesNegadas(context);
    }
  }

  void erroPermissoesNegadas(BuildContext context) {
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
              "Para usar o aplicativo, precisamos de acesso ao seu GPS, Câmera, Microfone e Notificações.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
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
            _buildPermissionItem(
              Icons.notifications_active,
              "Notificações",
              "Para receber avisos e respostas",
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => pedePermissoes(context),
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

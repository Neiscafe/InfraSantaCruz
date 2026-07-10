import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class SeletorLocalizacao extends StatelessWidget {
  final void Function(PickedData pickedData) onPicked;

  const SeletorLocalizacao({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FlutterLocationPicker.withConfiguration(
        mapConfiguration: MapConfiguration(mapLanguage: 'pt'),
        userAgent: "InfraSantaCruz/1.0 (guilhermeneis132@gmail.com)",
        onPicked: (PickedData pickedData) {
          onPicked(pickedData);
          Navigator.pop(context);
        },
      ),
    );
  }
}

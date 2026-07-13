import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class SeletorLocalizacao extends StatelessWidget {
  final void Function(PickedData pickedData) onPicked;
  final LatLong latLong;

  const SeletorLocalizacao({super.key, required this.latLong, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FlutterLocationPicker.withConfiguration(
        // initPosition: latLong,
        trackMyPosition: true,
        mapConfiguration: MapConfiguration(mapLanguage: 'pt'),
        userAgent: "InfraSantaCruz/1.0 (guilhermeneis132@gmail.com)",
        onPicked: (PickedData pickedData) {
          onPicked(pickedData);
          Navigator.pop(context);
        },
        selectButtonConfiguration: SelectButtonConfiguration(
          selectLocationButtonText: "Usar essa localização"
        ),
      ),
    );
  }
}

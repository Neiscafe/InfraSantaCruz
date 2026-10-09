import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class VisualizaLocal extends StatelessWidget {
  final LatLong latLong;

  const VisualizaLocal({super.key, required this.latLong});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: FlutterLocationPicker.withConfiguration(
        initPosition: latLong,
        mapConfiguration: MapConfiguration(mapLanguage: 'pt'),
        userAgent: "InfraSantaCruz/1.0 (guilhermeneis132@gmail.com)",
        selectButtonConfiguration: SelectButtonConfiguration(
          showSelectLocationButton: false,
        ),
        onPicked: (PickedData pickedData) {},
      ),
    );
  }
}

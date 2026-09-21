import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

typedef LocationCallback = void Function(Placemark, LatLong);

class SeletorLocalizacao extends StatefulWidget {
  final LocationCallback onPicked;
  final LatLong latLong;

  const SeletorLocalizacao({
    super.key,
    required this.latLong,
    required this.onPicked,
  });

  @override
  State<SeletorLocalizacao> createState() => _SeletorLocalizacaoState();
}

class _SeletorLocalizacaoState extends State<SeletorLocalizacao> {
  PickedData? pickedData;
  ValueNotifier<bool> loadingPlacemark = ValueNotifier(false);
  ValueNotifier<Placemark?> currentPlacemark = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Positioned.fill(child: _buildLocationPicker()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48, left: 16, right: 16),
              child: _selectLocationControls(context),
            ),
          ),
        ],
      ),
    );
  }

  Card _selectLocationControls(BuildContext context) {
    return Card(
      elevation: 10,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
            valueListenable: currentPlacemark,
            builder: (context, value, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  spacing: 8,
                  children: [
                    if (value != null)
                      Icon(Icons.location_on, color: Colors.red),
                    Expanded(
                      child: Text(
                        value == null
                            ? "Resolvendo endereço..."
                            : "${value.name}, ${value.thoroughfare}, ${value.subLocality}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _botaoSelecionar(context),
        ],
      ),
    );
  }

  FlutterLocationPicker _buildLocationPicker() {
    return FlutterLocationPicker.withConfiguration(
      searchConfiguration: SearchConfiguration(showSearchBar: false),
      controlsConfiguration: ControlsConfiguration(
        showLocationController: true,
      ),
      initPosition: widget.latLong,
      countryFilter: "br",
      markerConfiguration: MarkerConfiguration(
        markerIconOffset: 0,
        showMarkerShadow: true,
        markerIcon: Icon(Icons.location_on, size: 40, color: Colors.red),
      ),
      trackMyPosition: true,
      mapConfiguration: MapConfiguration(
        urlTemplate:
            'https://api.maptiler.com/maps/hybrid-v4/{z}/{x}/{y}.jpg?key=nwyFws2BC5ir8yBm0eKA',
        mapLanguage: 'pt',
        mapLoadingBackgroundColor: Colors.lightGreen,
      ),
      onChanged: reverseGeocodeLocation,
      userAgent: "InfraSantaCruz/1.0 (guilhermeneis132@gmail.com)",
      onPicked: (PickedData pickedData) {},
      selectButtonConfiguration: SelectButtonConfiguration(
        showSelectLocationButton: true,
        selectLocationButtonText: "Usar essa localização",
      ),
    );
  }

  TextButton _botaoSelecionar(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        padding: EdgeInsetsGeometry.all(24),
      ),
      onPressed: () async {
        if (pickedData == null || currentPlacemark.value == null) {
          return;
        }
        widget.onPicked(currentPlacemark.value!, pickedData!.latLong);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Row(
        spacing: 4,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pin_drop_outlined, size: 25),
          Text("Usar essa localização", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void reverseGeocodeLocation(PickedData? pickedData) async {
    if (loadingPlacemark.value) return;
    this.pickedData = pickedData;
    if (pickedData == null) return;
    loadingPlacemark.value = true;
    currentPlacemark.value = null;
    debugPrint(pickedData.toString());
    try {
      final res = await placemarkFromCoordinates(
        pickedData.latLong.latitude,
        pickedData.latLong.longitude,
      );
      if (res.isNotEmpty) {
        currentPlacemark.value = res.first;
        loadingPlacemark.value = false;
      }
    } catch (e) {
      return;
    }
  }
}

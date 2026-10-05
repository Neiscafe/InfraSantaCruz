import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

class EnderecoGeocode {
  final String? numero;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String cep;
  final double lat;
  final double lon;
  final Map<String, dynamic> fullJson;

  EnderecoGeocode({
    required this.numero,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.lat,
    required this.lon,
    required this.fullJson,
  });

  static EnderecoGeocode fromJson(Map<String, dynamic> json, LatLong latLong) {
    return EnderecoGeocode(
      numero: json["name"],
      logradouro: json["thoroughfare"] ?? "",
      bairro: json["subLocality"] ?? "",
      cidade: json["subAdministrativeArea"] ?? "",
      cep: json["postalCode"] ?? "",
      lat: latLong.latitude,
      lon: latLong.longitude,
      fullJson: json,
    );
  }
}

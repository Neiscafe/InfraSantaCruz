import 'package:supabase_flutter/supabase_flutter.dart';

class Usuario {
  final String usuarioId;
  final DateTime createdAt;
  final Map<String, dynamic> rawUserMetaData;
  final String? urlAvatar;
  final String fullName;
  final String email;
  final String? phone;

  Usuario({
    required this.usuarioId,
    required this.createdAt,
    required this.rawUserMetaData,
    required this.urlAvatar,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  static Usuario fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json["usuario_id"],
      createdAt: DateTime.parse(json["created_at"]),
      rawUserMetaData: json["raw_user_meta_data"],
      urlAvatar: json["url_avatar"],
      fullName: json["full_name"],
      email: json["email"],
      phone: json["phone"],
    );
  }

  static Usuario fromUser(User user) {
    return Usuario(
      usuarioId: user.id,
      createdAt: DateTime.parse(user.createdAt),
      rawUserMetaData: user.userMetadata ?? <String, dynamic>{},
      urlAvatar: user.userMetadata?["avatar_url"],
      fullName: user.userMetadata?["full_name"],
      email: user.email ?? "",
      phone: user.phone,
    );
  }
}

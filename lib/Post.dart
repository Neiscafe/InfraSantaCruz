class Post {
  final String id;
  final String title;
  final String description;
  final String location;
  final double lon;
  final double lat;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.lon,
    required this.lat,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      title: map['title'],
      location: map['location'] ?? '',
      description: map['description'],
      lon: map['lon'],
      lat: map['lat'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "lon": lon,
      "lat": lat,
      "location": location,
    };
  }
}

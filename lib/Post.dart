class Post {
  final String id;
  final String title;
  final String location;
  Post({required this.id, required this.title, required this.location});
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
    );
  }
}
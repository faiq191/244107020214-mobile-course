import 'dart:convert';

class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'body': body};
  }

  String toJson() => json.encode(toMap());
  factory Post.fromJson(String source) => Post.fromMap(json.decode(source));
}

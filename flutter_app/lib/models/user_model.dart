class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final DateTime createdAt;

  AppUser({required this.id, required this.name, required this.username, required this.email, required this.createdAt});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final int? imageId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    this.imageId,
    required this.createdAt,
  });

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      roles: List<String>.from(json['roles']),
      imageId: json['imageId'] != null 
          ? (json['imageId'] is String ? int.parse(json['imageId']) : json['imageId']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'roles': roles,
      'imageId': imageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // Helper method to get full name
  String get fullName => '$firstName $lastName';
  
  // Helper method to check if user has a specific role
  bool hasRole(String role) => roles.contains(role);
  
  // Helper method to check if user is an admin
  bool get isAdmin => hasRole('ADMIN');
}
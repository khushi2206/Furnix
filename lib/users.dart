class Users {
  String id;
  String name;
  int age;
  String email;

  Users({
    required this.id,
    required this.name,
    required this.age,
    required this.email,
  });

  factory Users.fromMap(Map<String, dynamic> data) {
    return Users(
      id: data['id'],
      name: data['name'],
      age: data['age'],
      email: data['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'email': email,
    };
  }
}

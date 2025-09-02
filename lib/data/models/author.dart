class Author {
  final String id;
  final String name;
  const Author({required this.id, required this.name});

  factory Author.fromMap(Map<String, dynamic> map) =>
      Author(id: map['id'] as String, name: map['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

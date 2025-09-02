class Category {
  final String id;
  final String name;
  const Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) =>
      Category(id: map['id'] as String, name: map['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

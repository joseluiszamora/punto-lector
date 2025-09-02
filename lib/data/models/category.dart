class Category {
  final String id;
  final String name;
  final String? color; // Hex como '#RRGGBB'
  const Category({required this.id, required this.name, this.color});

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    color: map['color'] as String?,
  );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'color': color}
        ..removeWhere((k, v) => v == null);
}

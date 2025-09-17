class Category {
  final String id;
  final String name;
  final String? description;
  final String? color; // Hex como '#RRGGBB'
  final String? parentId;
  final int level;
  final int sortOrder;
  final List<Category> children;
  final int childrenCount;
  final int bookCount;
  final String? fullPath;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.parentId,
    this.level = 0,
    this.sortOrder = 0,
    this.children = const [],
    this.childrenCount = 0,
    this.bookCount = 0,
    this.fullPath,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String?,
    color: map['color'] as String?,
    parentId: map['parent_id'] as String?,
    level: (map['level'] as int?) ?? 0,
    sortOrder: (map['sort_order'] as int?) ?? 0,
    children:
        map['children'] != null
            ? (map['children'] as List).map((e) => Category.fromMap(e)).toList()
            : const [],
    childrenCount: (map['children_count'] as int?) ?? 0,
    bookCount: (map['book_count'] as int?) ?? 0,
    fullPath: map['full_path'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color,
    'parent_id': parentId,
    'level': level,
    'sort_order': sortOrder,
    'children_count': childrenCount,
    'book_count': bookCount,
    'full_path': fullPath,
  }..removeWhere((k, v) => v == null);

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? parentId,
    int? level,
    int? sortOrder,
    List<Category>? children,
    int? childrenCount,
    int? bookCount,
    String? fullPath,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    color: color ?? this.color,
    parentId: parentId ?? this.parentId,
    level: level ?? this.level,
    sortOrder: sortOrder ?? this.sortOrder,
    children: children ?? this.children,
    childrenCount: childrenCount ?? this.childrenCount,
    bookCount: bookCount ?? this.bookCount,
    fullPath: fullPath ?? this.fullPath,
  );

  // Helper methods
  bool get isMainCategory => parentId == null && level == 0;
  bool get isSubcategory => parentId != null && level > 0;
  bool get hasChildren => childrenCount > 0 || children.isNotEmpty;
  bool get hasBooks => bookCount > 0;

  @override
  String toString() =>
      'Category(id: $id, name: $name, level: $level, children: ${children.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

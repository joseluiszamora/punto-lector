class Author {
  final String id;
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? photoUrl;
  final String? nationalityId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Author({
    required this.id,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.photoUrl,
    this.nationalityId,
    this.createdAt,
    this.updatedAt,
  });

  factory Author.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      // adm: acepta 'YYYY-MM-DD' o ISO
      return DateTime.tryParse(s);
    }

    return Author(
      id: map['id'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String?,
      birthDate: _parseDate(map['birth_date']),
      deathDate: _parseDate(map['death_date']),
      photoUrl: map['photo_url'] as String?,
      nationalityId: map['nationality_id'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'bio': bio,
    'birth_date': birthDate?.toIso8601String(),
    'death_date': deathDate?.toIso8601String(),
    'photo_url': photoUrl,
    'nationality_id': nationalityId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

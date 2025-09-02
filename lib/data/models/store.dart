class Store {
  final String? id;
  final String ownerUid;
  final String name;
  final String? managerName;
  final String? address;
  final String? city;
  final List<int> openDays;
  final String? openHour; // HH:mm
  final String? closeHour; // HH:mm
  final double? lat;
  final double? lng;
  final String? phone;
  final String? description;
  final String? photoUrl;
  final bool active;

  const Store({
    this.id,
    required this.ownerUid,
    required this.name,
    this.managerName,
    this.address,
    this.city,
    this.openDays = const [1, 2, 3, 4, 5],
    this.openHour,
    this.closeHour,
    this.lat,
    this.lng,
    this.phone,
    this.description,
    this.photoUrl,
    this.active = true,
  });

  factory Store.fromMap(Map<String, dynamic> map) => Store(
    id: map['id'] as String?,
    ownerUid: map['owner_uid'] as String,
    name: map['name'] as String,
    managerName: map['manager_name'] as String?,
    address: map['address'] as String?,
    city: map['city'] as String?,
    openDays:
        (map['open_days'] as List?)?.map((e) => (e as num).toInt()).toList() ??
        const [1, 2, 3, 4, 5],
    openHour: map['open_hour'] as String?,
    closeHour: map['close_hour'] as String?,
    lat: (map['lat'] as num?)?.toDouble(),
    lng: (map['lng'] as num?)?.toDouble(),
    phone: map['phone'] as String?,
    description: map['description'] as String?,
    photoUrl: map['photo_url'] as String?,
    active: (map['active'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_uid': ownerUid,
    'name': name,
    'manager_name': managerName,
    'address': address,
    'city': city,
    'open_days': openDays,
    'open_hour': openHour,
    'close_hour': closeHour,
    'lat': lat,
    'lng': lng,
    'phone': phone,
    'description': description,
    'photo_url': photoUrl,
    'active': active,
  }..removeWhere((key, value) => value == null);

  Map<String, dynamic> toInsert() {
    final m = toMap();
    m.remove('id');
    return m;
  }
}

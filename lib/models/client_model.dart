class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String company;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.company,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'company': company,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    address: json['address'],
    company: json['company'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? company,
    DateTime? createdAt,
  }) => Client(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    company: company ?? this.company,
    createdAt: createdAt ?? this.createdAt,
  );
}
class Borrower {
  Borrower({
    this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  Borrower copyWith({
    int? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
  }) {
    return Borrower(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Borrower.fromMap(Map<String, Object?> map) {
    return Borrower(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

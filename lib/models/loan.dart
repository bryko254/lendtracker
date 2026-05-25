class Loan {
  Loan({
    this.id,
    required this.borrowerId,
    required this.principalMinor,
    required this.lentDate,
    this.dueDate,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  final int? id;
  final int borrowerId;
  final int principalMinor;
  final DateTime lentDate;
  final DateTime? dueDate;
  final String? notes;
  final String status;
  final DateTime createdAt;

  Loan copyWith({
    int? id,
    int? borrowerId,
    int? principalMinor,
    DateTime? lentDate,
    DateTime? dueDate,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
      principalMinor: principalMinor ?? this.principalMinor,
      lentDate: lentDate ?? this.lentDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Loan.fromMap(Map<String, Object?> map) {
    return Loan(
      id: map['id'] as int?,
      borrowerId: map['borrower_id'] as int,
      principalMinor: map['principal_minor'] as int,
      lentDate: DateTime.fromMillisecondsSinceEpoch(
        map['lent_date'] as int,
      ),
      dueDate: map['due_date'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      notes: map['notes'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'borrower_id': borrowerId,
      'principal_minor': principalMinor,
      'lent_date': lentDate.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'notes': notes,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

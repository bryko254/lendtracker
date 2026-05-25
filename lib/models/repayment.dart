class Repayment {
  Repayment({
    this.id,
    required this.loanId,
    required this.amountMinor,
    required this.date,
    this.method,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final int loanId;
  final int amountMinor;
  final DateTime date;
  final String? method;
  final String? notes;
  final DateTime createdAt;

  Repayment copyWith({
    int? id,
    int? loanId,
    int? amountMinor,
    DateTime? date,
    String? method,
    String? notes,
    DateTime? createdAt,
  }) {
    return Repayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Repayment.fromMap(Map<String, Object?> map) {
    return Repayment(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      amountMinor: map['amount_minor'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      method: map['method'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'amount_minor': amountMinor,
      'date': date.millisecondsSinceEpoch,
      'method': method,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

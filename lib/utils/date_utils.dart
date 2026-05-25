import '../models/loan_with_totals.dart';

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isOverdue(LoanWithTotals loan) {
  final dueDate = loan.loan.dueDate;
  if (dueDate == null) {
    return false;
  }
  final today = dateOnly(DateTime.now());
  final due = dateOnly(dueDate);
  return today.isAfter(due) && loan.remainingMinor > 0 && loan.loan.status == 'open';
}

import 'loan.dart';

class LoanWithTotals {
  LoanWithTotals({
    required this.loan,
    required this.repaidMinor,
  });

  final Loan loan;
  final int repaidMinor;

  int get remainingMinor => loan.principalMinor - repaidMinor;
}

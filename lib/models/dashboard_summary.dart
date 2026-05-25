class DashboardSummary {
  DashboardSummary({
    required this.totalLentMinor,
    required this.totalRepaidMinor,
    required this.totalOutstandingMinor,
    required this.overdueCount,
    required this.overdueOutstandingMinor,
  });

  final int totalLentMinor;
  final int totalRepaidMinor;
  final int totalOutstandingMinor;
  final int overdueCount;
  final int overdueOutstandingMinor;
}

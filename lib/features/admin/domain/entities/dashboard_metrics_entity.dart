import 'package:equatable/equatable.dart';

class DashboardMetricsEntity extends Equatable {
  const DashboardMetricsEntity({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.newCustomersThisWeek,
  });

  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int totalProducts;
  final int newCustomersThisWeek;

  @override
  List<Object?> get props =>
      [totalRevenue, totalOrders, pendingOrders, totalProducts, newCustomersThisWeek];
}

class SalesSeriesPoint extends Equatable {
  const SalesSeriesPoint({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  List<Object?> get props => [label, amount];
}

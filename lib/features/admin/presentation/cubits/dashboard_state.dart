part of 'dashboard_cubit.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    this.metrics,
    this.salesSeries = const [],
    this.recentOrders = const [],
    this.topProducts = const [],
    this.chartDays = 7,
    this.errorMessage,
  });

  const DashboardState.initial()
      : this(
          status: DashboardStatus.initial,
        );

  final DashboardStatus status;
  final DashboardMetricsEntity? metrics;
  final List<SalesSeriesPoint> salesSeries;
  final List<OrderEntity> recentOrders;
  final List<ProductEntity> topProducts;
  final int chartDays;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardMetricsEntity? metrics,
    List<SalesSeriesPoint>? salesSeries,
    List<OrderEntity>? recentOrders,
    List<ProductEntity>? topProducts,
    int? chartDays,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      salesSeries: salesSeries ?? this.salesSeries,
      recentOrders: recentOrders ?? this.recentOrders,
      topProducts: topProducts ?? this.topProducts,
      chartDays: chartDays ?? this.chartDays,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        metrics,
        salesSeries,
        recentOrders,
        topProducts,
        chartDays,
        errorMessage,
      ];
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/entities/order_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState.initial());

  final AdminDashboardRepository _repository;

  StreamSubscription<List<OrderEntity>>? _ordersSub;
  StreamSubscription<List<ProductEntity>>? _productsSub;

  Future<void> load({int chartDays = 7}) async {
    emit(state.copyWith(status: DashboardStatus.loading, chartDays: chartDays));

    final metrics = await _repository.getMetrics();
    final series = await _repository.getSalesSeries(days: chartDays);

    metrics.fold(
      (f) => emit(state.copyWith(status: DashboardStatus.failure, errorMessage: f.message)),
      (m) {
        series.fold(
          (f2) => emit(state.copyWith(status: DashboardStatus.failure, errorMessage: f2.message)),
          (s) {
            emit(
              state.copyWith(
                status: DashboardStatus.success,
                metrics: m,
                salesSeries: s,
                errorMessage: null,
              ),
            );
          },
        );
      },
    );

    await _ordersSub?.cancel();
    await _productsSub?.cancel();

    _ordersSub = _repository.watchRecentOrders(limit: 12).listen(
          (orders) => emit(state.copyWith(recentOrders: orders)),
        );
    _productsSub = _repository.watchTopSellingProducts(limit: 8).listen(
          (products) => emit(state.copyWith(topProducts: products)),
        );
  }

  Future<void> setChartRange(int days) => load(chartDays: days);

  @override
  Future<void> close() async {
    await _ordersSub?.cancel();
    await _productsSub?.cancel();
    return super.close();
  }
}

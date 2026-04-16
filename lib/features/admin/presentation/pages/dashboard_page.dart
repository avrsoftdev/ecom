import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../common/domain/entities/order_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/repositories/admin_order_repository.dart';
import '../cubits/dashboard_cubit.dart';
import '../widgets/metric_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading && state.metrics == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.failure && state.metrics == null) {
          return Center(child: Text(state.errorMessage ?? 'Error'));
        }

        final m = state.metrics;
        return LayoutBuilder(
          builder: (context, constraints) {
            final cross = constraints.maxWidth >= 1100
                ? 3
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 16.h),
                  if (m != null)
                    GridView.count(
                      crossAxisCount: cross,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      childAspectRatio: cross == 1 ? 2.4 : 1.6,
                      children: [
                        MetricCard(
                          title: 'Total revenue',
                          value: formatCurrency(m.totalRevenue),
                          icon: Icons.payments_rounded,
                        ),
                        MetricCard(
                          title: 'Total orders',
                          value: '${m.totalOrders}',
                          icon: Icons.shopping_bag_rounded,
                        ),
                        MetricCard(
                          title: 'Pending orders',
                          value: '${m.pendingOrders}',
                          icon: Icons.hourglass_top_rounded,
                        ),
                        MetricCard(
                          title: 'Products',
                          value: '${m.totalProducts}',
                          icon: Icons.inventory_2_rounded,
                        ),
                        MetricCard(
                          title: 'New customers (7d)',
                          value: '${m.newCustomersThisWeek}',
                          icon: Icons.person_add_alt_1_rounded,
                        ),
                      ],
                    ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Text(
                        'Sales',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('Week')),
                          ButtonSegment(value: 30, label: Text('Month')),
                        ],
                        selected: {state.chartDays},
                        onSelectionChanged: (s) {
                          context.read<DashboardCubit>().setChartRange(s.first);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 260.h,
                    child: _SalesChart(points: state.salesSeries),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Top selling products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  _TopProductsTable(products: state.topProducts),
                  SizedBox(height: 24.h),
                  Text(
                    'Recent orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8.h),
                  _RecentOrdersTable(orders: state.recentOrders),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.points});

  final List<SalesSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No sales data yet'));
    }
    final maxY = points.map((e) => e.amount).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.1,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final label = points[i].label.split('-').skip(1).join('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(
                v >= 1000 ? formatCompactCurrency(v) : formatCurrencyNoDecimals(v),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].amount,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  const _TopProductsTable({required this.products});

  final List<ProductEntity> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No products yet'),
        ),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Sold')),
            DataColumn(label: Text('Price')),
          ],
          rows: products
              .map(
                (p) => DataRow(
                  cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text('${p.soldCount}')),
                    DataCell(Text(formatCurrency(p.effectivePrice))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _RecentOrdersTable extends StatelessWidget {
  const _RecentOrdersTable({required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminOrderRepository>();
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No orders yet'),
        ),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Order')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Status')),
          ],
          rows: orders
              .map(
                (o) => DataRow(
                  cells: [
                    DataCell(Text(o.id.length <= 8 ? o.id : o.id.substring(0, 8))),
                    DataCell(Text(o.customerEmail ?? o.userId)),
                    DataCell(Text(formatCurrency(o.total))),
                    DataCell(
                      _OrderStatusDropdown(
                        orderId: o.id,
                        value: o.status,
                        repository: repo,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

const _kOrderStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

class _OrderStatusDropdown extends StatefulWidget {
  const _OrderStatusDropdown({
    required this.orderId,
    required this.value,
    required this.repository,
  });

  final String orderId;
  final String value;
  final AdminOrderRepository repository;

  @override
  State<_OrderStatusDropdown> createState() => _OrderStatusDropdownState();
}

class _OrderStatusDropdownState extends State<_OrderStatusDropdown> {
  late String _v = widget.value;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _kOrderStatuses.contains(_v) ? _v : 'pending',
      items: _kOrderStatuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (nv) async {
        if (nv == null || nv == _v) return;
        setState(() => _v = nv);
        await widget.repository.updateOrderStatus(widget.orderId, nv);
      },
    );
  }
}

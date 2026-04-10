import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../common/domain/entities/customer_profile_entity.dart';
import '../../domain/repositories/admin_customer_repository.dart';

class CustomersAdminPage extends StatelessWidget {
  const CustomersAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminCustomerRepository>();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customers',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 16.h),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search (client-side)',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {},
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<CustomerProfileEntity>>(
              stream: repo.watchCustomers(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = list[i];
                    return ListTile(
                      title: Text(u.displayName ?? u.email),
                      subtitle: Text('${u.email} · ${u.role}'),
                      trailing: TextButton(
                        onPressed: () => context.go('/admin/customers/${u.id}'),
                        child: const Text('View'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

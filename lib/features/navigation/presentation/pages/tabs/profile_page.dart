import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/fresh_veggie_header.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Navigate to login screen after successful logout
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: const FreshVeggieHeader(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName!
                                : 'Profile',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                          if (user?.phoneNumber != null &&
                              user!.phoneNumber!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              user.phoneNumber!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage:
                          user?.photoURL != null && user!.photoURL!.isNotEmpty
                              ? NetworkImage(user.photoURL!)
                              : null,
                      child: user?.photoURL == null || user!.photoURL!.isEmpty
                          ? Icon(
                              Icons.person_outline_rounded,
                              size: 50,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().signOut();
                              },
                        icon: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onError,
                                  ),
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(isLoading ? 'Logging out...' : 'Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

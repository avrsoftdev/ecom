import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../cubits/notification_cubit.dart';
import '../cubits/notification_state.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    print('🔔 NotificationPage: initState called');
    
    // Add listener to debug state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔔 NotificationPage: Post frame callback - loading notifications');
      context.read<NotificationCubit>().loadNotifications();
      
      // Listen to state changes for debugging
      context.read<NotificationCubit>().stream.listen((state) {
        print('🔔 NotificationPage: State changed to: ${state.runtimeType}');
        if (state is NotificationLoaded) {
          print('🔔 NotificationPage: Loaded ${state.notifications.length} notifications');
          print('🔔 NotificationPage: Unread count: ${state.unreadCount}');
          for (final notification in state.notifications) {
            print('🔔 NotificationPage: - ${notification.title} (${notification.type})');
          }
        } else if (state is NotificationError) {
          print('🔔 NotificationPage: Error - ${state.message}');
        } else if (state is NotificationLoading) {
          print('🔔 NotificationPage: Loading...');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        foregroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () => context.read<NotificationCubit>().markAllAsRead(),
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          print('🔔 NotificationPage: BlocBuilder called with state: ${state.runtimeType}');
          
          if (state is NotificationLoading) {
            print('🔔 NotificationPage: Showing loading state');
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006400)),
            );
          }

          if (state is NotificationError) {
            print('🔔 NotificationPage: Showing error state: ${state.message}');
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 56.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => context.read<NotificationCubit>().loadNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006400),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationLoaded) {
            print('🔔 NotificationPage: Showing loaded state with ${state.notifications.length} notifications');
            
            if (state.notifications.isEmpty) {
              print('🔔 NotificationPage: No notifications to display');
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 56.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'We\'ll notify you when your order status changes',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            print('🔔 NotificationPage: Building ListView with ${state.notifications.length} notifications');
            return RefreshIndicator(
              onRefresh: () => context.read<NotificationCubit>().loadNotifications(),
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  print('🔔 NotificationPage: Building notification card ${index + 1}/${state.notifications.length}: ${notification.title}');
                  return _NotificationCard(
                    notification: notification,
                    onTap: () {
                      if (!notification.isRead) {
                        context.read<NotificationCubit>().markAsRead(notification.id);
                      }
                    },
                  );
                },
              ),
            );
          }

          print('🔔 NotificationPage: Unknown state type: ${state.runtimeType}');
          return Center(
            child: Text(
              'Unknown state: ${state.runtimeType}',
              style: GoogleFonts.poppins(fontSize: 16.sp),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.orderDispatched:
        return Icons.local_shipping_outlined;
      case NotificationType.orderDelivered:
        return Icons.check_circle_outline;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.orderDispatched:
        return Colors.blue;
      case NotificationType.orderDelivered:
        return Colors.green;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final color = _getColor();
    final time = _formatTime(notification.timestamp);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              margin: EdgeInsets.only(left: 8.w),
                              decoration: const BoxDecoration(
                                color: Color(0xFF006400),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

import 'package:flutter/material.dart';

import '../services/app_update_service.dart';

class AppUpdateSnackBarListener extends StatefulWidget {
  AppUpdateSnackBarListener({
    super.key,
    required this.child,
    AppUpdateService? updateService,
  }) : updateService = updateService ?? AppUpdateService();

  final Widget child;
  final AppUpdateService updateService;

  @override
  State<AppUpdateSnackBarListener> createState() =>
      _AppUpdateSnackBarListenerState();
}

class _AppUpdateSnackBarListenerState extends State<AppUpdateSnackBarListener> {
  bool _hasCheckedThisLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_hasCheckedThisLaunch || !mounted) {
      return;
    }

    _hasCheckedThisLaunch = true;

    final updateInfo = await widget.updateService.checkForUpdate();
    if (!mounted || updateInfo == null) {
      return;
    }

    _showUpdateSnackBar(updateInfo);
  }

  void _showUpdateSnackBar(AppUpdateInfo updateInfo) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          duration: const Duration(days: 1),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          content: _UpdateSnackBarContent(
            updateInfo: updateInfo,
            onUpdatePressed: () => _openStore(updateInfo.storeUrl),
            onDismissed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }

  Future<void> _openStore(String storeUrl) async {
    final didOpen = await widget.updateService.openPlayStore(storeUrl);
    if (!mounted || didOpen) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Unable to open the Play Store. Please try again later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _UpdateSnackBarContent extends StatelessWidget {
  const _UpdateSnackBarContent({
    required this.updateInfo,
    required this.onUpdatePressed,
    required this.onDismissed,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback onUpdatePressed;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.system_update_alt_rounded,
                color: colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A new Bazariyo update is available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version ${updateInfo.storeVersion} is ready on the Play Store.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onInverseSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: onUpdatePressed,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Update App',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismissed,
              icon: const Icon(Icons.close_rounded),
              color: colorScheme.onInverseSurface,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

part of '../../screens/dashboard_screen.dart';

class _GlobalDeviceButton extends StatelessWidget {
  const _GlobalDeviceButton({required this.controller, required this.compact});

  final DashboardController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final device = controller.selectedDevice;
    if (compact) {
      return IconButton(
        tooltip: device == null
            ? 'Manage child devices'
            : 'Active device: ${device.childName}',
        onPressed: () => _openChildDevicesScreen(context, controller),
        icon: Badge(
          isLabelVisible: device?.isOnline ?? false,
          smallSize: 8,
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.smartphone),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          device?.isOnline ?? false ? Icons.wifi : Icons.wifi_off,
          size: 18,
          color: device?.isOnline ?? false
              ? AppColors.secondary
              : AppColors.muted,
        ),
        label: Text(
          device == null
              ? 'Child devices'
              : '${device.childName} - ${device.deviceName}',
          overflow: TextOverflow.ellipsis,
        ),
        tooltip: 'Manage child devices',
        onPressed: () => _openChildDevicesScreen(context, controller),
      ),
    );
  }
}

class _ActiveDeviceBanner extends StatelessWidget {
  const _ActiveDeviceBanner({
    required this.controller,
    this.message = 'This section follows the active child device.',
    this.compact = false, // Kept for API compatibility, but layout is unified
  });

  final DashboardController controller;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final device = controller.selectedDevice;
    if (device == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              device.childName.isNotEmpty ? device.childName[0].toUpperCase() : '?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensures minimal height
              children: [
                Text(
                  '${device.childName} • ${device.deviceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _openChildDevicesScreen(context, controller),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Change',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicePickerCard extends StatelessWidget {
  const _DevicePickerCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Active child device',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showPairDeviceDialog(context, controller),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Pair'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose once here. Apps, websites, reports, and protection status will use this device.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final device in controller.devices) ...[
              _DevicePickerTile(
                device: device,
                selected: device.id == controller.selectedDevice?.id,
                onTap: () => controller.selectDevice(device.id),
              ),
              if (device != controller.devices.last)
                const Divider(height: 12, color: AppColors.border),
            ],
          ],
        ),
      ),
    );
  }
}

class _DevicePickerTile extends StatelessWidget {
  const _DevicePickerTile({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final ChildDevice device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${device.deviceName} - ${device.platform}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OnlineStatusPill(isOnline: device.isOnline),
          ],
        ),
      ),
    );
  }
}

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice? device;

  @override
  Widget build(BuildContext context) {
    final currentDevice = device;
    if (currentDevice == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabledCount = currentDevice.enabledProtectionCount;
    final protections = [
      (
        'Usage access',
        currentDevice.usageAccessEnabled,
        Icons.query_stats_rounded,
      ),
      (
        'VPN / domain filter',
        currentDevice.vpnFilterEnabled,
        Icons.vpn_lock_outlined,
      ),
      (
        'Background service',
        currentDevice.backgroundServiceRunning,
        Icons.sync_rounded,
      ),
      (
        'Protected mode',
        currentDevice.protectedModeEnabled,
        Icons.shield_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Child device protection',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '$enabledCount of 4 protections enabled',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$enabledCount/4',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${currentDevice.deviceName} - synced ${DateFormatter.relative(currentDevice.lastSyncAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 260 &&
                        MediaQuery.textScalerOf(context).scale(12) <= 18
                    ? 2
                    : 1;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final protection in protections)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns,
                        child: _ProtectionTile(
                          label: protection.$1,
                          enabled: protection.$2,
                          icon: protection.$3,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionTile extends StatelessWidget {
  const _ProtectionTile({
    required this.label,
    required this.enabled,
    required this.icon,
  });
  final String label;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = enabled ? colors.secondary : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      enabled
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        enabled ? 'Active' : 'Needs setup',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paired devices',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '${controller.devices.length} devices connected',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.devices.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final device in controller.devices) ...[
              _DeviceModernTile(
                device: device,
                isSelected: device.id == controller.selectedDevice?.id,
                onTap: () => controller.selectDevice(device.id),
              ),
              if (device != controller.devices.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceModernTile extends StatelessWidget {
  const _DeviceModernTile({
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  final ChildDevice device;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withValues(alpha: 0.04) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? colors.primary.withValues(alpha: 0.3) 
                : colors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 300;
            
            final textContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.childName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, size: 14, color: colors.primary),
                    ]
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.deviceName} • ${device.platform}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            );

            return Row(
              crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      device.childName.isEmpty ? '?' : device.childName[0].toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isSelected ? colors.primary : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: isCompact 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            textContent,
                            const SizedBox(height: 8),
                            OnlineStatusPill(isOnline: device.isOnline),
                          ],
                        )
                      : textContent,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 10),
                  OnlineStatusPill(isOnline: device.isOnline),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

part of '../../screens/dashboard_screen.dart';

class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.devices.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.devices_other,
        title: 'No devices paired',
        message: 'Pair a child Android device to start monitoring apps.',
        action: FilledButton.icon(
          onPressed: () => _showPairDeviceDialog(context, controller),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Pair device'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final menu = _DeviceMenu(controller: controller, expanded: true);
            final details = Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OnlineStatusPill(
                  isOnline: controller.selectedDevice?.isOnline ?? false,
                ),
                StatusPill(
                  label:
                      '${controller.selectedDevice?.enabledProtectionCount ?? 0}/4 protections',
                  icon: Icons.verified_user_outlined,
                  color: AppColors.primary,
                ),
                StatusPill(
                  label:
                      'Code ${controller.selectedDevice?.pairingCode ?? '-'}',
                  icon: Icons.qr_code_2,
                  color: AppColors.accent,
                ),
              ],
            );
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [menu, const SizedBox(height: 12), details],
              );
            }
            return Row(
              children: [
                Expanded(child: menu),
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeviceMenu extends StatelessWidget {
  const _DeviceMenu({required this.controller, this.expanded = false});

  final DashboardController controller;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final selectedId = controller.selectedDevice?.id;
    final selectedDeviceExists = controller.devices.any(
      (device) => device.id == selectedId,
    );
    final effectiveSelectedId = selectedDeviceExists ? selectedId : null;
    final canSelect = !controller.isLoading && controller.devices.isNotEmpty;

    final menu = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return DropdownButtonFormField<String>(
          key: ValueKey(effectiveSelectedId),
          initialValue: effectiveSelectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Child device',
            hintText: canSelect ? 'Select a device' : 'No devices paired',
            prefixIcon: const Icon(Icons.smartphone),
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 12 : 16,
            ),
          ),
          items: [
            for (final device in controller.devices)
              DropdownMenuItem(
                value: device.id,
                child: _DeviceMenuItem(device: device),
              ),
          ],
          selectedItemBuilder: (context) => [
            for (final device in controller.devices)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  compact
                      ? device.childName
                      : '${device.childName} - ${device.deviceName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: canSelect
              ? (value) {
                  if (value != null) {
                    controller.selectDevice(value);
                  }
                }
              : null,
        );
      },
    );

    if (expanded) {
      return menu;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: menu,
    );
  }
}

class _DeviceMenuItem extends StatelessWidget {
  const _DeviceMenuItem({required this.device});

  final ChildDevice device;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OnlineStatusPill(isOnline: device.isOnline),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.childName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                device.deviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProtectionStatusCard extends StatelessWidget {
  const _ProtectionStatusCard({required this.device});

  final ChildDevice? device;

  @override
  Widget build(BuildContext context) {
    final currentDevice = device;
    if (currentDevice == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child device protection',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentDevice.deviceName} last synced ${DateFormatter.relative(currentDevice.lastSyncAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _ProtectionRow(
              label: 'Usage access',
              enabled: currentDevice.usageAccessEnabled,
              icon: Icons.query_stats,
            ),
            _ProtectionRow(
              label: 'VPN/domain filter',
              enabled: currentDevice.vpnFilterEnabled,
              icon: Icons.vpn_lock_outlined,
            ),
            _ProtectionRow(
              label: 'Background service',
              enabled: currentDevice.backgroundServiceRunning,
              icon: Icons.sync,
            ),
            _ProtectionRow(
              label: 'Protected mode',
              enabled: currentDevice.protectedModeEnabled,
              icon: Icons.admin_panel_settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionRow extends StatelessWidget {
  const _ProtectionRow({
    required this.label,
    required this.enabled,
    required this.icon,
  });

  final String label;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          final title = Row(
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.secondary : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
          final status = StatusPill(
            label: enabled ? 'Active' : 'Needs setup',
            icon: enabled ? Icons.check_circle : Icons.info_outline,
            color: enabled ? AppColors.secondary : AppColors.accent,
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 8), status],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 10),
              status,
            ],
          );
        },
      ),
    );
  }
}

class _DeviceListCard extends StatelessWidget {
  const _DeviceListCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paired devices',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            for (final device in controller.devices) ...[
              InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                onTap: () => controller.selectDevice(device.id),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${device.deviceName} - ${device.platform}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: isCompact
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: device.id == controller.selectedDevice?.id
                                  ? 0.18
                                  : 0.08,
                            ),
                            child: Text(
                              device.childName.isEmpty
                                  ? '?'
                                  : device.childName[0],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isCompact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      details,
                                      const SizedBox(height: 8),
                                      OnlineStatusPill(
                                        isOnline: device.isOnline,
                                      ),
                                    ],
                                  )
                                : details,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 10),
                            OnlineStatusPill(isOnline: device.isOnline),
                          ],
                        ],
                      ),
                    );
                  },
                ),
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

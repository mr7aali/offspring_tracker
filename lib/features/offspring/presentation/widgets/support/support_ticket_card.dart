part of '../../screens/dashboard_screen.dart';

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.onStatusChanged,
  });

  final _SupportTicket ticket;
  final ValueChanged<_SupportTicketStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        ticket.subject,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.id} - Updated ${DateFormatter.relative(ticket.updatedAt)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_SupportTicketStatus>(
                  tooltip: 'Change status',
                  onSelected: onStatusChanged,
                  itemBuilder: (context) => [
                    for (final status in _SupportTicketStatus.values)
                      PopupMenuItem(
                        value: status,
                        child: Text(status.actionLabel),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: ticket.status.label,
                  icon: ticket.status.icon,
                  color: ticket.status.color,
                ),
                StatusPill(
                  label: ticket.priority.label,
                  icon: Icons.flag_outlined,
                  color: ticket.priority.color,
                ),
                StatusPill(
                  label: ticket.category.label,
                  icon: ticket.category.icon,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.mail_outline,
              title: 'Requester',
              value: ticket.requesterEmail,
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              title: 'Created',
              value: DateFormatter.compact(ticket.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

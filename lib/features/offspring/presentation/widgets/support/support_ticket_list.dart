part of '../../screens/dashboard_screen.dart';

class _SupportTicketList extends StatelessWidget {
  const _SupportTicketList({
    required this.filter,
    required this.tickets,
    required this.onFilterChanged,
    required this.onStatusChanged,
  });

  final _SupportTicketFilter filter;
  final List<_SupportTicket> tickets;
  final ValueChanged<_SupportTicketFilter> onFilterChanged;
  final void Function(_SupportTicket ticket, _SupportTicketStatus status)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tickets',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${tickets.length} shown',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<_SupportTicketFilter>(
            segments: [
              for (final item in _SupportTicketFilter.values)
                ButtonSegment(
                  value: item,
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
            selected: {filter},
            onSelectionChanged: (values) {
              onFilterChanged(values.first);
            },
          ),
        ),
        const SizedBox(height: 14),
        if (tickets.isEmpty)
          const EmptyStateWidget(
            icon: Icons.confirmation_number_outlined,
            title: 'No tickets found',
            message: 'Create a ticket or switch filters to see requests.',
          )
        else
          for (final ticket in tickets) ...[
            _SupportTicketCard(
              ticket: ticket,
              onStatusChanged: (status) => onStatusChanged(ticket, status),
            ),
            const SizedBox(height: AppSizes.cardGap),
          ],
      ],
    );
  }
}

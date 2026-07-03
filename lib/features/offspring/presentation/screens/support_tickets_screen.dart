part of 'dashboard_screen.dart';

final List<_SupportTicket> _demoSupportTickets = [
  _SupportTicket(
    id: 'SUP-1002',
    subject: 'Pairing code expired for Leo phone',
    description:
        'The child device shows the old pairing code and does not connect after refresh.',
    category: _SupportTicketCategory.pairing,
    priority: _SupportTicketPriority.high,
    status: _SupportTicketStatus.open,
    requesterEmail: AppStrings.demoEmail,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  _SupportTicket(
    id: 'SUP-1001',
    subject: 'Need help reviewing website rules',
    description:
        'Some blocked domains still appear in browser search results. Please confirm if this is expected.',
    category: _SupportTicketCategory.webRules,
    priority: _SupportTicketPriority.normal,
    status: _SupportTicketStatus.waitingParent,
    requesterEmail: AppStrings.demoEmail,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

enum _SupportTicketStatus { open, waitingParent, resolved }

enum _SupportTicketPriority { low, normal, high, urgent }

enum _SupportTicketCategory { pairing, appRules, webRules, billing, bug }

enum _SupportTicketFilter { all, open, waitingParent, resolved }

class _SupportTicket {
  const _SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.requesterEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final String description;
  final _SupportTicketCategory category;
  final _SupportTicketPriority priority;
  final _SupportTicketStatus status;
  final String requesterEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  _SupportTicket copyWith({_SupportTicketStatus? status, DateTime? updatedAt}) {
    return _SupportTicket(
      id: id,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: status ?? this.status,
      requesterEmail: requesterEmail,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension _SupportTicketStatusUi on _SupportTicketStatus {
  String get label {
    switch (this) {
      case _SupportTicketStatus.open:
        return 'Open';
      case _SupportTicketStatus.waitingParent:
        return 'Waiting parent';
      case _SupportTicketStatus.resolved:
        return 'Resolved';
    }
  }

  String get actionLabel {
    switch (this) {
      case _SupportTicketStatus.open:
        return 'Mark open';
      case _SupportTicketStatus.waitingParent:
        return 'Mark waiting parent';
      case _SupportTicketStatus.resolved:
        return 'Mark resolved';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketStatus.open:
        return Icons.mark_email_unread_outlined;
      case _SupportTicketStatus.waitingParent:
        return Icons.pending_actions_outlined;
      case _SupportTicketStatus.resolved:
        return Icons.check_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case _SupportTicketStatus.open:
        return AppColors.accent;
      case _SupportTicketStatus.waitingParent:
        return AppColors.secondary;
      case _SupportTicketStatus.resolved:
        return AppColors.muted;
    }
  }
}

extension _SupportTicketPriorityUi on _SupportTicketPriority {
  String get label {
    switch (this) {
      case _SupportTicketPriority.low:
        return 'Low';
      case _SupportTicketPriority.normal:
        return 'Normal';
      case _SupportTicketPriority.high:
        return 'High';
      case _SupportTicketPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case _SupportTicketPriority.low:
        return AppColors.muted;
      case _SupportTicketPriority.normal:
        return AppColors.primary;
      case _SupportTicketPriority.high:
        return AppColors.accent;
      case _SupportTicketPriority.urgent:
        return AppColors.danger;
    }
  }
}

extension _SupportTicketCategoryUi on _SupportTicketCategory {
  String get label {
    switch (this) {
      case _SupportTicketCategory.pairing:
        return 'Device pairing';
      case _SupportTicketCategory.appRules:
        return 'App rules';
      case _SupportTicketCategory.webRules:
        return 'Website rules';
      case _SupportTicketCategory.billing:
        return 'Billing';
      case _SupportTicketCategory.bug:
        return 'Bug report';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketCategory.pairing:
        return Icons.qr_code_scanner;
      case _SupportTicketCategory.appRules:
        return Icons.apps_outlined;
      case _SupportTicketCategory.webRules:
        return Icons.public_off_outlined;
      case _SupportTicketCategory.billing:
        return Icons.receipt_long_outlined;
      case _SupportTicketCategory.bug:
        return Icons.bug_report_outlined;
    }
  }
}

extension _SupportTicketFilterUi on _SupportTicketFilter {
  String get label {
    switch (this) {
      case _SupportTicketFilter.all:
        return 'All';
      case _SupportTicketFilter.open:
        return 'Open';
      case _SupportTicketFilter.waitingParent:
        return 'Waiting';
      case _SupportTicketFilter.resolved:
        return 'Resolved';
    }
  }

  IconData get icon {
    switch (this) {
      case _SupportTicketFilter.all:
        return Icons.inbox_outlined;
      case _SupportTicketFilter.open:
        return Icons.mark_email_unread_outlined;
      case _SupportTicketFilter.waitingParent:
        return Icons.pending_actions_outlined;
      case _SupportTicketFilter.resolved:
        return Icons.check_circle_outline;
    }
  }
}

class _SupportTicketsScreen extends StatefulWidget {
  const _SupportTicketsScreen();

  @override
  State<_SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<_SupportTicketsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  _SupportTicketCategory _category = _SupportTicketCategory.pairing;
  _SupportTicketPriority _priority = _SupportTicketPriority.normal;
  _SupportTicketFilter _filter = _SupportTicketFilter.all;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<_SupportTicket> get _filteredTickets {
    return _demoSupportTickets.where((ticket) {
      switch (_filter) {
        case _SupportTicketFilter.all:
          return true;
        case _SupportTicketFilter.open:
          return ticket.status == _SupportTicketStatus.open;
        case _SupportTicketFilter.waitingParent:
          return ticket.status == _SupportTicketStatus.waitingParent;
        case _SupportTicketFilter.resolved:
          return ticket.status == _SupportTicketStatus.resolved;
      }
    }).toList();
  }

  void _submitTicket() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = appDependencies.authController.currentUser;
    final now = DateTime.now();
    final ticket = _SupportTicket(
      id: 'SUP-${1001 + _demoSupportTickets.length}',
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      status: _SupportTicketStatus.open,
      requesterEmail: user?.email ?? AppStrings.demoEmail,
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      _demoSupportTickets.insert(0, ticket);
      _filter = _SupportTicketFilter.all;
      _subjectController.clear();
      _descriptionController.clear();
      _category = _SupportTicketCategory.pairing;
      _priority = _SupportTicketPriority.normal;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${ticket.id} created.')));
  }

  void _updateTicketStatus(_SupportTicket ticket, _SupportTicketStatus status) {
    final index = _demoSupportTickets.indexWhere(
      (item) => item.id == ticket.id,
    );
    if (index == -1) {
      return;
    }

    setState(() {
      _demoSupportTickets[index] = ticket.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final openTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.open)
        .length;
    final waitingTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.waitingParent)
        .length;
    final resolvedTickets = _demoSupportTickets
        .where((ticket) => ticket.status == _SupportTicketStatus.resolved)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Support tickets')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsPageHeader(
                    icon: Icons.support_agent_outlined,
                    title: 'Support tickets',
                    subtitle:
                        'Create requests, track progress, and manage parent support issues.',
                  ),
                  const SizedBox(height: AppSizes.sectionGap),
                  _MetricGrid(
                    children: [
                      MetricCard(
                        label: 'All tickets',
                        value: '${_demoSupportTickets.length}',
                        icon: Icons.confirmation_number_outlined,
                        color: AppColors.primary,
                      ),
                      MetricCard(
                        label: 'Open',
                        value: '$openTickets',
                        icon: Icons.mark_email_unread_outlined,
                        color: AppColors.accent,
                      ),
                      MetricCard(
                        label: 'Waiting parent',
                        value: '$waitingTickets',
                        icon: Icons.pending_actions_outlined,
                        color: AppColors.secondary,
                      ),
                      MetricCard(
                        label: 'Resolved',
                        value: '$resolvedTickets',
                        icon: Icons.check_circle_outline,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sectionGap),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 920;
                      final form = _SupportTicketForm(
                        formKey: _formKey,
                        subjectController: _subjectController,
                        descriptionController: _descriptionController,
                        category: _category,
                        priority: _priority,
                        onCategoryChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                        onPriorityChanged: (value) {
                          if (value != null) {
                            setState(() => _priority = value);
                          }
                        },
                        onSubmit: _submitTicket,
                      );
                      final tickets = _SupportTicketList(
                        filter: _filter,
                        tickets: _filteredTickets,
                        onFilterChanged: (filter) {
                          setState(() => _filter = filter);
                        },
                        onStatusChanged: _updateTicketStatus,
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            form,
                            const SizedBox(height: AppSizes.sectionGap),
                            tickets,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 360, child: form),
                          const SizedBox(width: AppSizes.sectionGap),
                          Expanded(child: tickets),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

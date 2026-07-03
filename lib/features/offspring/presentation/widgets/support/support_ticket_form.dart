part of '../../screens/dashboard_screen.dart';

class _SupportTicketForm extends StatelessWidget {
  const _SupportTicketForm({
    required this.formKey,
    required this.subjectController,
    required this.descriptionController,
    required this.category,
    required this.priority,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final _SupportTicketCategory category;
  final _SupportTicketPriority priority;
  final ValueChanged<_SupportTicketCategory?> onCategoryChanged;
  final ValueChanged<_SupportTicketPriority?> onPriorityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create ticket',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: subjectController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) => Validators.requiredText(value, 'Subject'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_SupportTicketCategory>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final item in _SupportTicketCategory.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_SupportTicketPriority>(
                initialValue: priority,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: [
                  for (final item in _SupportTicketPriority.values)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: onPriorityChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) =>
                    Validators.requiredText(value, 'Description'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add),
                label: const Text('Create ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

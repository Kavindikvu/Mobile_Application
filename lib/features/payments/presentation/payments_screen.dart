import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/payment.dart';
import '../../../../core/theme/tokens.dart';
import '../data/payment_repository.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  PaymentStatus? _selectedFilter;
  String _selectedChildId = 'all';

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsProvider('user_123'));
    final summaryAsync = ref.watch(paymentSummaryProvider('user_123'));
    
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add payment',
                onPressed: () => _addPayment(context),
              ),
              IconButton(
                icon: const Icon(Icons.credit_card),
                tooltip: 'Payment methods',
                onPressed: () => _managePaymentMethods(context),
              ),
            ],
          ),
        ),
        _SummarySection(summaryAsync: summaryAsync),
        _FilterBar(
            selectedFilter: _selectedFilter,
            selectedChildId: _selectedChildId,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            onChildChanged: (childId) {
              setState(() {
                _selectedChildId = childId;
              });
            },
          ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => const _LoadingState(),
            error: (error, stackTrace) => _ErrorState(error: error.toString()),
            data: (payments) {
              final filteredPayments = _filterPayments(payments);
              if (filteredPayments.isEmpty) {
                return _EmptyState(
                  hasFilter: _selectedFilter != null || _selectedChildId != 'all',
                  onClearFilters: () {
                    setState(() {
                      _selectedFilter = null;
                      _selectedChildId = 'all';
                    });
                  },
                );
              }
              return _PaymentList(payments: filteredPayments);
            },
          ),
        ),
      ],
    );
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    var filtered = payments;
    
    if (_selectedFilter != null) {
      filtered = filtered.where((p) => p.status == _selectedFilter).toList();
    }
    
    if (_selectedChildId != 'all') {
      filtered = filtered.where((p) => p.childId == _selectedChildId).toList();
    }
    
    // Sort by due date (overdue first, then by due date)
    filtered.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });
    
    return filtered;
  }

  void _addPayment(BuildContext context) {
    // TODO: Implement add payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment not yet implemented')),
    );
  }

  void _managePaymentMethods(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final AsyncValue<PaymentSummary> summaryAsync;

  const _SummarySection({required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: summaryAsync.when(
        loading: () => const _SummaryLoadingState(),
        error: (error, stackTrace) => const _SummaryErrorState(),
        data: (summary) => _SummaryContent(summary: summary),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final PaymentSummary summary;

  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Due',
                amount: summary.formattedTotalAmount,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Paid',
                amount: summary.formattedPaidAmount,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Pending',
                amount: summary.formattedPendingAmount,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Overdue',
                amount: summary.formattedOverdueAmount,
                color: const Color(0xFFF44336),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LinearProgressIndicator(
          value: summary.completionPercentage / 100,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${summary.completionPercentage.toStringAsFixed(1)}% Complete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final PaymentStatus? selectedFilter;
  final String selectedChildId;
  final ValueChanged<PaymentStatus?> onFilterChanged;
  final ValueChanged<String> onChildChanged;

  const _FilterBar({
    required this.selectedFilter,
    required this.selectedChildId,
    required this.onFilterChanged,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: selectedFilter == null,
                        onTap: () => onFilterChanged(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...PaymentStatus.values.map((status) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: _getStatusLabel(status),
                          isSelected: selectedFilter == status,
                          onTap: () => onFilterChanged(status),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedChildId,
                  decoration: const InputDecoration(
                    labelText: 'Child',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Children')),
                    DropdownMenuItem(value: 'child_1', child: Text('Emma Doe')),
                    DropdownMenuItem(value: 'child_2', child: Text('Liam Doe')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChildChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<Payment> payments;

  const _PaymentList({required this.payments});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _PaymentCard(payment: payment);
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: InkWell(
        onTap: () => _handlePaymentTap(context, payment),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: payment.isOverdue 
                ? Border.all(
                    color: const Color(0xFFF44336).withOpacity(0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.description,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            payment.formattedAmount,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: payment.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: payment.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                payment.statusIcon,
                                size: 16,
                                color: payment.statusColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                payment.statusText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: payment.statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          payment.timeText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      payment.method.typeIcon,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      payment.method.name.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (payment.childId != null)
                      Text(
                        _getChildName(payment.childId!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (payment.isOverdue) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: const Color(0xFFF44336),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'This payment is overdue. Please pay immediately to avoid late fees.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFF44336),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getChildName(String childId) {
    switch (childId) {
      case 'child_1':
        return 'Emma Doe';
      case 'child_2':
        return 'Liam Doe';
      default:
        return 'Unknown Child';
    }
  }

  void _handlePaymentTap(BuildContext context, Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(payment: payment),
      ),
    );
  }
}

class PaymentDetailScreen extends ConsumerWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        actions: [
          if (payment.isPending || payment.isFailed)
            TextButton(
              onPressed: () => _payNow(context, payment),
              child: const Text('Pay Now'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentInfoCard(payment: payment),
            const SizedBox(height: AppSpacing.lg),
            _PaymentActionsCard(payment: payment),
            if (payment.receiptUrl != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ReceiptCard(payment: payment),
            ],
          ],
        ),
      ),
    );
  }

  void _payNow(BuildContext context, Payment payment) {
    // TODO: Implement payment processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment processing not yet implemented')),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  final Payment payment;

  const _PaymentInfoCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoRow(
              label: 'Description',
              value: payment.description,
            ),
            _InfoRow(
              label: 'Amount',
              value: payment.formattedAmount,
            ),
            _InfoRow(
              label: 'Status',
              value: payment.statusText,
              valueColor: payment.statusColor,
            ),
            _InfoRow(
              label: 'Method',
              value: payment.method.name.toUpperCase(),
            ),
            _InfoRow(
              label: 'Due Date',
              value: '${payment.dueDate.month}/${payment.dueDate.day}/${payment.dueDate.year}',
            ),
            if (payment.paidDate != null)
              _InfoRow(
                label: 'Paid Date',
                value: '${payment.paidDate!.month}/${payment.paidDate!.day}/${payment.paidDate!.year}',
              ),
            if (payment.transactionId != null)
              _InfoRow(
                label: 'Transaction ID',
                value: payment.transactionId!,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentActionsCard extends StatelessWidget {
  final Payment payment;

  const _PaymentActionsCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (payment.isPending || payment.isFailed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _payNow(context, payment),
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay Now'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (payment.isCompleted && payment.receiptUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadReceipt(context, payment),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Receipt'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (payment.isPending) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelPayment(context, payment),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Payment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _payNow(BuildContext context, Payment payment) {
    // TODO: Implement payment processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment processing not yet implemented')),
    );
  }

  void _downloadReceipt(BuildContext context, Payment payment) {
    // TODO: Implement receipt download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download not yet implemented')),
    );
  }

  void _cancelPayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel payment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment cancelled')),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Payment payment;

  const _ReceiptCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Payment Receipt'),
              subtitle: Text('Transaction ID: ${payment.transactionId}'),
              trailing: const Icon(Icons.download),
              onTap: () => _downloadReceipt(context, payment),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReceipt(BuildContext context, Payment payment) {
    // TODO: Implement receipt download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download not yet implemented')),
    );
  }
}

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider('user_123'));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addPaymentMethod(context),
          ),
        ],
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading payment methods: $error'),
        ),
        data: (methods) => _PaymentMethodsList(methods: methods),
      ),
    );
  }

  void _addPaymentMethod(BuildContext context) {
    // TODO: Implement add payment method
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add payment method not yet implemented')),
    );
  }
}

class _PaymentMethodsList extends StatelessWidget {
  final List<PaymentMethodInfo> methods;

  const _PaymentMethodsList({required this.methods});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        return _PaymentMethodCard(method: method);
      },
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodInfo method;

  const _PaymentMethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(method.typeIcon),
        title: Text(method.displayName),
        subtitle: method.expiryDate != null 
            ? Text('Expires ${method.expiryDate}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  'DEFAULT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, method, value),
              itemBuilder: (context) => [
                if (!method.isDefault)
                  PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Set as Default'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Remove', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, PaymentMethodInfo method, String action) {
    switch (action) {
      case 'set_default':
        // TODO: Implement set default
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set as default not yet implemented')),
        );
        break;
      case 'edit':
        // TODO: Implement edit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit not yet implemented')),
        );
        break;
      case 'remove':
        _removePaymentMethod(context, method);
        break;
    }
  }

  void _removePaymentMethod(BuildContext context, PaymentMethodInfo method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: Text('Are you sure you want to remove ${method.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement remove payment method
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method removed')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Loading and Error States
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Loading payments...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilter,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilter ? 'No payments found' : 'No payments yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasFilter
                  ? 'Try adjusting your filters'
                  : 'Your payment history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onClearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryLoadingState extends StatelessWidget {
  const _SummaryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _SummaryErrorState extends StatelessWidget {
  const _SummaryErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error loading summary',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

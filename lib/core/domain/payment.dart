import 'package:flutter/material.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet,
  cash,
}

enum PaymentType {
  tuition,
  fees,
  materials,
  activities,
  other,
}

class Payment {
  final String id;
  final String userId;
  final String? childId;
  final double amount;
  final String currency;
  final PaymentType type;
  final PaymentStatus status;
  final PaymentMethod method;
  final String description;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? transactionId;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.userId,
    this.childId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.method,
    required this.description,
    required this.dueDate,
    this.paidDate,
    this.transactionId,
    this.receiptUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      childId: json['childId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: PaymentType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PaymentType.tuition,
      ),
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (method) => method.name == json['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      description: json['description'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null 
          ? DateTime.parse(json['paidDate'] as String) 
          : null,
      transactionId: json['transactionId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'childId': childId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'method': method.name,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    String? childId,
    double? amount,
    String? currency,
    PaymentType? type,
    PaymentStatus? status,
    PaymentMethod? method,
    String? description,
    DateTime? dueDate,
    DateTime? paidDate,
    String? transactionId,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      childId: childId ?? this.childId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      method: method ?? this.method,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessing => status == PaymentStatus.processing;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isRefunded => status == PaymentStatus.refunded;
  
  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueDate);
  bool get isDueSoon => !isCompleted && DateTime.now().add(const Duration(days: 3)).isAfter(dueDate);
  
  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
  String get statusText => status.name.toUpperCase();
  String get typeText => type.name.toUpperCase();
  
  Color get statusColor {
    switch (status) {
      case PaymentStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case PaymentStatus.processing:
        return const Color(0xFF2196F3); // Blue
      case PaymentStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.failed:
        return const Color(0xFFF44336); // Red
      case PaymentStatus.cancelled:
        return const Color(0xFF9E9E9E); // Grey
      case PaymentStatus.refunded:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  IconData get statusIcon {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  String get timeText {
    if (isCompleted && paidDate != null) {
      final now = DateTime.now();
      final difference = now.difference(paidDate!);
      
      if (difference.inDays < 1) {
        return 'Paid today';
      } else if (difference.inDays < 7) {
        return 'Paid ${difference.inDays}d ago';
      } else {
        return 'Paid ${paidDate!.month}/${paidDate!.day}';
      }
    } else if (isOverdue) {
      final now = DateTime.now();
      final difference = now.difference(dueDate);
      return 'Overdue by ${difference.inDays}d';
    } else if (isDueSoon) {
      final now = DateTime.now();
      final difference = dueDate.difference(now);
      return 'Due in ${difference.inDays}d';
    } else {
      return 'Due ${dueDate.month}/${dueDate.day}';
    }
  }
}

class PaymentMethodInfo {
  final String id;
  final PaymentMethod type;
  final String name;
  final String? lastFourDigits;
  final String? expiryDate;
  final bool isDefault;
  final String? iconUrl;
  final Map<String, dynamic>? metadata;

  const PaymentMethodInfo({
    required this.id,
    required this.type,
    required this.name,
    this.lastFourDigits,
    this.expiryDate,
    this.isDefault = false,
    this.iconUrl,
    this.metadata,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String,
      type: PaymentMethod.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => PaymentMethod.creditCard,
      ),
      name: json['name'] as String,
      lastFourDigits: json['lastFourDigits'] as String?,
      expiryDate: json['expiryDate'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      iconUrl: json['iconUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate,
      'isDefault': isDefault,
      'iconUrl': iconUrl,
      'metadata': metadata,
    };
  }

  String get displayName {
    if (lastFourDigits != null) {
      return '$name ending in $lastFourDigits';
    }
    return name;
  }

  IconData get typeIcon {
    switch (type) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.account_balance_wallet;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.digitalWallet:
        return Icons.wallet;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }
}

// Icon support for raw enum PaymentMethod
extension PaymentMethodIconExtension on PaymentMethod {
  IconData get typeIcon {
    switch (this) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.account_balance_wallet;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.digitalWallet:
        return Icons.wallet;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }
}

class PaymentSummary {
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;
  final int totalPayments;
  final int completedPayments;
  final int pendingPayments;
  final int overduePayments;
  final String currency;

  const PaymentSummary({
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.totalPayments,
    required this.completedPayments,
    required this.pendingPayments,
    required this.overduePayments,
    required this.currency,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      pendingAmount: (json['pendingAmount'] as num).toDouble(),
      overdueAmount: (json['overdueAmount'] as num).toDouble(),
      totalPayments: json['totalPayments'] as int,
      completedPayments: json['completedPayments'] as int,
      pendingPayments: json['pendingPayments'] as int,
      overduePayments: json['overduePayments'] as int,
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
      'totalPayments': totalPayments,
      'completedPayments': completedPayments,
      'pendingPayments': pendingPayments,
      'overduePayments': overduePayments,
      'currency': currency,
    };
  }

  double get completionPercentage => 
      totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0.0;
  
  String get formattedTotalAmount => '$currency ${totalAmount.toStringAsFixed(2)}';
  String get formattedPaidAmount => '$currency ${paidAmount.toStringAsFixed(2)}';
  String get formattedPendingAmount => '$currency ${pendingAmount.toStringAsFixed(2)}';
  String get formattedOverdueAmount => '$currency ${overdueAmount.toStringAsFixed(2)}';
}

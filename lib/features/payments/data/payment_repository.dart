import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/asset_data_provider.dart';
import '../../../../core/domain/payment.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

class PaymentRepository {
  const PaymentRepository(this._assetDataProvider);

  final AssetDataProvider _assetDataProvider;

  Future<List<Payment>> getPayments(String userId) async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/payments.json');
      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  Future<List<Payment>> getPaymentsByStatus(String userId, PaymentStatus status) async {
    try {
      final payments = await getPayments(userId);
      return payments.where((p) => p.status == status).toList();
    } catch (e) {
      throw Exception('Failed to load payments by status: $e');
    }
  }

  Future<List<Payment>> getOverduePayments(String userId) async {
    try {
      final payments = await getPayments(userId);
      return payments.where((p) => p.isOverdue).toList();
    } catch (e) {
      throw Exception('Failed to load overdue payments: $e');
    }
  }

  Future<PaymentSummary> getPaymentSummary(String userId) async {
    try {
      final data = await _assetDataProvider.loadMap('assets/data/payment_summary.json');
      return PaymentSummary.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load payment summary: $e');
    }
  }

  Future<List<PaymentMethodInfo>> getPaymentMethods(String userId) async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/payment_methods.json');
      return data.map((json) => PaymentMethodInfo.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load payment methods: $e');
    }
  }

  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final payments = await getPayments('user_123'); // TODO: Get from auth context
      return payments.where((p) => p.id == paymentId).firstOrNull;
    } catch (e) {
      throw Exception('Failed to load payment: $e');
    }
  }

  Future<void> processPayment(String paymentId, PaymentMethod method) async {
    // TODO: Implement payment processing
    // This would typically integrate with payment gateway
  }

  Future<void> cancelPayment(String paymentId) async {
    // TODO: Implement payment cancellation
    // This would typically update the backend
  }

  Future<void> addPaymentMethod(PaymentMethodInfo method) async {
    // TODO: Implement add payment method
    // This would typically update the backend
  }

  Future<void> removePaymentMethod(String methodId) async {
    // TODO: Implement remove payment method
    // This would typically update the backend
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    // TODO: Implement set default payment method
    // This would typically update the backend
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final assetDataProvider = ref.watch(assetDataProviderProvider);
  return PaymentRepository(assetDataProvider);
});

final paymentsProvider = FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPayments(userId);
});

final paymentsByStatusProvider = FutureProvider.family<List<Payment>, (String, PaymentStatus)>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentsByStatus(params.$1, params.$2);
});

final overduePaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getOverduePayments(userId);
});

final paymentSummaryProvider = FutureProvider.family<PaymentSummary, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentSummary(userId);
});

final paymentMethodsProvider = FutureProvider.family<List<PaymentMethodInfo>, String>((ref, userId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentMethods(userId);
});

final paymentByIdProvider = FutureProvider.family<Payment?, String>((ref, paymentId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentById(paymentId);
});

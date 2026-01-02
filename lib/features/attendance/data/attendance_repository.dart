import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/asset_data_provider.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final asset = ref.watch(assetDataProviderProvider);
  return AttendanceRepository(asset);
});

class AttendanceRepository {
  AttendanceRepository(this._asset);
  final AssetDataProvider _asset;

  static const _assetPath = 'assets/data/attendance.json';

  Future<List<Map<String, dynamic>>> fetchAttendance() async {
    final list = await _asset.loadList(_assetPath);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

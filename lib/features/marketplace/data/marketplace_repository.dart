import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/asset_data_provider.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final asset = ref.watch(assetDataProviderProvider);
  return MarketplaceRepository(asset);
});

class MarketplaceRepository {
  MarketplaceRepository(this._asset);
  final AssetDataProvider _asset;

  static const _assetPath = 'assets/data/marketplace.json';

  Future<List<Map<String, dynamic>>> fetchListings() async {
    final list = await _asset.loadList(_assetPath);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

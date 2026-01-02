import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AssetDataProvider {
  const AssetDataProvider();

  Future<List<dynamic>> loadList(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final decoded = json.decode(jsonStr);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['items'] is List) return (decoded['items'] as List);
    return const [];
  }

  Future<Map<String, dynamic>> loadMap(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final decoded = json.decode(jsonStr);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }
}

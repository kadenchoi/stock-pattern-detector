import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pattern_detection.dart';

class PatternCacheService {
  static final PatternCacheService instance = PatternCacheService._();
  PatternCacheService._();

  static const _boxName = 'pattern_cache';
  static const _key = 'latest_patterns';
  Box<String>? _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> cachePatterns(List<PatternMatch> patterns) async {
    if (_box == null) await initialize();
    final jsonList = patterns.map((p) => jsonEncode(p.toJson())).toList();
    await _box!.put(_key, jsonEncode(jsonList));
  }

  Future<List<PatternMatch>> getCachedPatterns() async {
    if (_box == null) await initialize();
    final raw = _box!.get(_key);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .cast<String>()
        .map(
            (s) => PatternMatch.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> clear() async {
    if (_box == null) await initialize();
    await _box!.delete(_key);
  }
}

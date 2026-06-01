import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Ready Player Me avatar .glb URL across sessions.
///
/// Exposes [avatarGlbUrl] as a [ValueNotifier] so that any widget
/// wrapped in a [ValueListenableBuilder] updates reactively the moment
/// a new avatar is saved — even across tabs in an IndexedStack.
class AvatarService {
  static const _kKey = 'rpm_avatar_glb_url';

  /// Reactive source of truth — null means no avatar is saved yet.
  final avatarGlbUrl = ValueNotifier<String?>(null);

  /// Loads the persisted URL from SharedPreferences and seeds
  /// [avatarGlbUrl]. Call once at startup (see app.dart).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    avatarGlbUrl.value = prefs.getString(_kKey);
  }

  /// Returns the persisted URL directly from SharedPreferences.
  /// Useful for one-off reads (e.g. on screen init).
  Future<String?> loadGlbUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey);
  }

  Future<void> saveGlbUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, url);
    avatarGlbUrl.value = url;
  }

  Future<void> clearGlbUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
    avatarGlbUrl.value = null;
  }

  void dispose() => avatarGlbUrl.dispose();
}
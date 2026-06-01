import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aura_fit/services/avatar_service.dart';
import 'package:aura_fit/theme/app_theme.dart';

// ─── Ready Player Me public demo URL ─────────────────────────────────────────
//
// `?frameApi`   — activates the JS postMessage bridge (required).
// `&clearCache` — forces RPM to reload fresh each time.
//
// To use your own subdomain once you have a RPM developer account, replace
// this constant with: 'https://<your-app>.readyplayer.me/avatar?frameApi'
//
const String _kRpmUrl =
    'https://demo.readyplayer.me/avatar?frameApi&clearCache';

/// Embedded tab screen hosting the Ready Player Me 3-D avatar creator.
///
/// Captures the exported `.glb` URL via JS postMessage, persists it
/// through [AvatarService] (SharedPreferences), and exposes the value
/// via [AvatarService.avatarGlbUrl] (a [ValueNotifier]) so that any
/// other screen (e.g. Profile) that uses [ValueListenableBuilder]
/// updates automatically without a page reload.
class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late final WebViewController _ctrl;

  bool    _loading         = true;
  String? _savedGlbUrl;    // persisted value loaded from AvatarService
  String? _capturedGlbUrl; // just exported, awaiting user confirmation

  // ── JS ↔ Flutter bridge ───────────────────────────────────────────────────
  static const _kChannel = 'RpmBridge';

  // Raw string → no Dart string-interpolation; 'RpmBridge' is a JS identifier
  // that matches the channel name registered on the WebViewController.
  static const _kListenerScript = r'''
    (function() {
      if (window.__rpmInjected) return;
      window.__rpmInjected = true;
      window.addEventListener('message', function(evt) {
        try {
          var d = (typeof evt.data === 'string')
              ? JSON.parse(evt.data)
              : evt.data;
          if (d && d.source === 'readyplayerme') {
            RpmBridge.postMessage(JSON.stringify(d));
          }
        } catch(e) {}
      });
    })();
  ''';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    _loadSavedAvatar();
  }

  void _initWebViewController() {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(kBackground)
      ..addJavaScriptChannel(_kChannel, onMessageReceived: _handleRpmMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted:  (_) => setState(() => _loading = true),
          onPageFinished: (_) {
            setState(() => _loading = false);
            // Re-inject on every page finish so the listener survives
            // internal navigations within the RPM creator.
            _ctrl.runJavaScript(_kListenerScript);
          },
          onWebResourceError: (err) =>
              debugPrint('[RPM] Error ${err.errorCode}: ${err.description}'),
        ),
      )
      ..loadRequest(Uri.parse(_kRpmUrl));
  }

  Future<void> _loadSavedAvatar() async {
    final url = await context.read<AvatarService>().loadGlbUrl();
    if (mounted) setState(() => _savedGlbUrl = url);
  }

  // ── RPM message handler ───────────────────────────────────────────────────

  void _handleRpmMessage(JavaScriptMessage msg) {
    try {
      final payload = jsonDecode(msg.message) as Map<String, dynamic>;
      final event   = payload['eventName'] as String?;
      debugPrint('[RPM] event=$event');

      if (event == 'v1.avatar.exported') {
        final data   = payload['data'] as Map<String, dynamic>?;
        final glbUrl = data?['url'] as String?;
        if (glbUrl != null && glbUrl.isNotEmpty) {
          setState(() => _capturedGlbUrl = glbUrl);
          _showSaveDialog(glbUrl);
        }
      }
    } catch (e) {
      debugPrint('[RPM] Parse error: $e');
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveAvatar(String url) async {
    await context.read<AvatarService>().saveGlbUrl(url);
    if (!mounted) return;
    setState(() {
      _savedGlbUrl    = url;
      _capturedGlbUrl = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: kBackground, size: 16),
            SizedBox(width: 8),
            Text('Avatar saved & synced globally!'),
          ],
        ),
        backgroundColor: kAccent,
        duration:        Duration(seconds: 3),
      ),
    );
  }

  void _showSaveDialog(String glbUrl) {
    final avatarId = glbUrl
        .split('/')
        .last
        .split('?')
        .first
        .replaceAll('.glb', '');
    final isUpdate = _savedGlbUrl != null;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: kAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              isUpdate ? 'Update Avatar?' : 'Avatar Ready!',
              style: const TextStyle(
                  color: kAccent, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUpdate
                  ? 'This will replace your saved avatar across the whole app.'
                  : 'Your 3D avatar has been exported and is ready to save.',
              style: const TextStyle(color: kTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Avatar ID', value: avatarId),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: glbUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:        kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: kIndigo.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        glbUrl,
                        style: const TextStyle(color: kIndigo, fontSize: 10),
                        maxLines:  3,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.copy_rounded, size: 14, color: kTextMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Edit Again',
                style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveAvatar(glbUrl);
            },
            child: Text(isUpdate ? 'Update Avatar' : 'Save Avatar'),
          ),
        ],
      ),
    );
  }

  void _reloadWebView() {
    setState(() {
      _capturedGlbUrl = null;
      _loading        = true;
    });
    _ctrl.loadRequest(Uri.parse(_kRpmUrl));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:       MainAxisSize.min,
          children: [
            const Text('My Avatar'),
            if (_savedGlbUrl != null)
              const Text(
                'Ready Player Me • saved',
                style: TextStyle(
                  color:      kAccent,
                  fontSize:   11,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh_rounded),
            tooltip: 'Reload creator',
            onPressed: _reloadWebView,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Saved-avatar banner ──────────────────────────────────────────
          if (_savedGlbUrl != null)
            _SavedBanner(glbUrl: _savedGlbUrl!),

          // ── WebView + overlays ───────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _ctrl),

                // Loading overlay
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _loading
                      ? Container(
                          key:   const ValueKey('loader'),
                          color: kBackground,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color:       kAccent,
                                  strokeWidth: 2.5,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Loading Avatar Creator…',
                                  style: TextStyle(
                                      color: kTextMuted, fontSize: 14),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Powered by Ready Player Me',
                                  style: TextStyle(
                                    color:     kTextMuted,
                                    fontSize:  11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),

                // Captured badge
                if (_capturedGlbUrl != null)
                  Positioned(
                    bottom: 16,
                    left:   16,
                    right:  16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color:        kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: kAccent, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Avatar captured — confirm in the dialog above.',
                              style: TextStyle(color: kAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved-avatar banner ──────────────────────────────────────────────────────

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.glbUrl});

  final String glbUrl;

  @override
  Widget build(BuildContext context) {
    final avatarId =
        glbUrl.split('/').last.split('?').first.replaceAll('.glb', '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:  kAccent.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: kAccent.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_in_ar_rounded, color: kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT AVATAR',
                  style: TextStyle(
                    color:         kAccent,
                    fontSize:      10,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'ID: $avatarId',
                  style: const TextStyle(color: kTextMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: glbUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:         Text('GLB URL copied to clipboard!'),
                  backgroundColor: kAccent,
                  duration:        Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        kAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Copy URL',
                    style: TextStyle(
                      color:      kAccent,
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.copy_rounded, color: kAccent, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:  ',
          style: const TextStyle(
            color:      kTextMuted,
            fontSize:   12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color:      kTextPrimary,
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
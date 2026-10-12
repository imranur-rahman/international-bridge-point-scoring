{{flutter_js}}
{{flutter_build_config}}

// Load the app without Flutter's own service worker. That worker removes
// itself and would also remove the app's worker (sw.js), which keeps the app
// available offline. Load CanvasKit from the app's own folder, not from the
// Google CDN, so that sw.js can store it for offline use.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});

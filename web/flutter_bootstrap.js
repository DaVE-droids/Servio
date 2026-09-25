{{flutter_js}}
{{flutter_build_config}}

// Servio loads Flutter without its service worker. Flutter has deprecated
// it, and it could keep serving an old build after a deploy; instead the
// hosting headers (firebase.json) make browsers check for a new version on
// every visit, which is cheap because unchanged files return "304".
_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});

// Fade out the HTML loading screen once Flutter has drawn its first frame.
window.addEventListener('flutter-first-frame', () => {
  const loader = document.getElementById('app-loader');
  if (!loader) {
    return;
  }
  loader.classList.add('is-done');
  setTimeout(() => loader.remove(), 400);
});

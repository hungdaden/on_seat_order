{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    
    // Remove the loading screen once the app is initialized
    const loadingElement = document.getElementById('loading');
    if (loadingElement) {
      loadingElement.remove();
    }
    
    await appRunner.runApp();
  }
});

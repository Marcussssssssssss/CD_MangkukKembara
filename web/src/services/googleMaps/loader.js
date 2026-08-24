const GOOGLE_MAPS_SCRIPT_ID = 'mangkuk-kembara-google-maps';
const GOOGLE_MAPS_CALLBACK = '__mangkukKembaraGoogleMapsReady';

const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY?.trim() || '';
const mapId = import.meta.env.VITE_GOOGLE_MAPS_MAP_ID?.trim() || 'DEMO_MAP_ID';

let googleMapsPromise = null;

export function isGoogleMapsConfigured() {
  return Boolean(apiKey);
}

export function getGoogleMapsMapId() {
  return mapId;
}

export function loadGoogleMaps() {
  if (!apiKey) {
    return Promise.reject(
      new Error('Google Maps is not configured. Add VITE_GOOGLE_MAPS_API_KEY and restart the web app.')
    );
  }

  if (window.google?.maps?.importLibrary) {
    return Promise.resolve(window.google.maps);
  }

  if (googleMapsPromise) return googleMapsPromise;

  googleMapsPromise = new Promise((resolve, reject) => {
    const finish = () => {
      if (window.google?.maps?.importLibrary) {
        resolve(window.google.maps);
      } else {
        googleMapsPromise = null;
        reject(new Error('Google Maps loaded without the required JavaScript API.'));
      }
    };

    const fail = () => {
      googleMapsPromise = null;
      reject(new Error('Google Maps could not be loaded. Check the API key, enabled APIs, and network connection.'));
    };

    const existingScript = document.getElementById(GOOGLE_MAPS_SCRIPT_ID);
    if (existingScript) {
      existingScript.addEventListener('load', finish, { once: true });
      existingScript.addEventListener('error', fail, { once: true });
      return;
    }

    window[GOOGLE_MAPS_CALLBACK] = () => {
      delete window[GOOGLE_MAPS_CALLBACK];
      finish();
    };

    const previousAuthFailure = window.gm_authFailure;
    window.gm_authFailure = () => {
      previousAuthFailure?.();
      fail();
    };

    const parameters = new URLSearchParams({
      key: apiKey,
      loading: 'async',
      callback: GOOGLE_MAPS_CALLBACK,
      libraries: 'maps,places,marker,geocoding',
      language: 'en',
      region: 'MY',
      v: 'weekly',
    });

    const script = document.createElement('script');
    script.id = GOOGLE_MAPS_SCRIPT_ID;
    script.src = `https://maps.googleapis.com/maps/api/js?${parameters.toString()}`;
    script.async = true;
    script.onerror = fail;
    document.head.appendChild(script);
  });

  return googleMapsPromise;
}

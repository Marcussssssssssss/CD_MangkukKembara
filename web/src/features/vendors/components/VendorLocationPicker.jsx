import { useEffect, useId, useRef, useState } from 'react';
import {
  getGoogleMapsMapId,
  isGoogleMapsConfigured,
  loadGoogleMaps,
} from '../../../services/googleMaps/loader';
import { hasValidVendorLocation } from '../services/vendorLocation';

const MALAYSIA_CENTER = { lat: 4.2105, lng: 101.9758 };

function toCoordinate(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function toPosition(location) {
  if (!location) return null;
  const latitude = typeof location.lat === 'function' ? location.lat() : toCoordinate(location.lat);
  const longitude = typeof location.lng === 'function' ? location.lng() : toCoordinate(location.lng);

  if (latitude === null || longitude === null) return null;
  return { lat: latitude, lng: longitude };
}

function getAdministrativeArea(addressComponents = []) {
  const stateComponent = addressComponents.find((component) => (
    component.types?.includes('administrative_area_level_1')
  ));

  return stateComponent?.longText || stateComponent?.long_name || null;
}

function getCountryCode(addressComponents = []) {
  const countryComponent = addressComponents.find((component) => component.types?.includes('country'));
  return countryComponent?.shortText || countryComponent?.short_name || null;
}

export default function VendorLocationPicker({
  value,
  error,
  disabled = false,
  onChange,
  onStateDetected,
}) {
  const searchId = useId();
  const helpId = useId();
  const autocompleteElement = useRef(null);
  const autocompleteContainerRef = useRef(null);
  const mapContainerRef = useRef(null);
  const disabledState = useRef(disabled);
  const [initialLocation] = useState(() => ({
    address_line: value.address_line,
    latitude: value.latitude,
    longitude: value.longitude,
    google_place_id: value.google_place_id,
  }));
  const [loadStatus, setLoadStatus] = useState(
    isGoogleMapsConfigured() ? 'loading' : 'configuration'
  );
  const [searchError, setSearchError] = useState('');
  const [mapError, setMapError] = useState('');

  useEffect(() => {
    if (!isGoogleMapsConfigured()) return undefined;

    let isDisposed = false;
    let marker = null;
    let placeAutocomplete = null;
    let handlePlaceSelection = null;
    let handleAutocompleteError = null;
    let confirmedPosition = null;
    const mapListeners = [];
    const autocompleteContainer = autocompleteContainerRef.current;
    const mapContainer = mapContainerRef.current;

    const initialize = async () => {
      try {
        setLoadStatus('loading');
        setSearchError('');
        setMapError('');
        await loadGoogleMaps();

        const [mapsLibrary, markerLibrary, placesLibrary, geocodingLibrary] = await Promise.all([
          window.google.maps.importLibrary('maps'),
          window.google.maps.importLibrary('marker'),
          window.google.maps.importLibrary('places'),
          window.google.maps.importLibrary('geocoding'),
        ]);

        if (isDisposed || !autocompleteContainer || !mapContainer) return;

        const initialPosition = hasValidVendorLocation(initialLocation)
          ? {
              lat: Number(initialLocation.latitude),
              lng: Number(initialLocation.longitude),
            }
          : null;
        confirmedPosition = initialPosition;

        const map = new mapsLibrary.Map(mapContainer, {
          center: initialPosition || MALAYSIA_CENTER,
          zoom: initialPosition ? 17 : 6,
          mapId: getGoogleMapsMapId(),
          mapTypeControl: false,
          streetViewControl: false,
          fullscreenControl: true,
          gestureHandling: 'cooperative',
        });

        const geocoder = new geocodingLibrary.Geocoder();
        marker = new markerLibrary.AdvancedMarkerElement({
          map,
          position: initialPosition || undefined,
          gmpDraggable: true,
          title: 'Selected vendor location. Drag the pin to fine-tune the address.',
        });

        const applyLocation = ({ address, position, placeId, addressComponents }) => {
          if (getCountryCode(addressComponents)?.toUpperCase() !== 'MY') {
            throw new Error('Select a location within Malaysia.');
          }

          confirmedPosition = position;
          onChange({
            address_line: address,
            latitude: Number(position.lat.toFixed(7)),
            longitude: Number(position.lng.toFixed(7)),
            google_place_id: placeId || null,
          });

          const detectedState = getAdministrativeArea(addressComponents);
          if (detectedState) onStateDetected(detectedState);
        };

        const reverseGeocode = async (position) => {
          if (!position) return;

          try {
            setLoadStatus('resolving');
            setMapError('');
            const response = await geocoder.geocode({ location: position, region: 'my' });
            if (isDisposed) return;

            const result = response.results?.[0];
            if (!result) {
              throw new Error('No address was found at that pin location.');
            }

            marker.position = position;
            applyLocation({
              address: result.formatted_address,
              position,
              placeId: result.place_id,
              addressComponents: result.address_components,
            });
            setLoadStatus('ready');
          } catch (geocodeError) {
            if (isDisposed) return;
            marker.position = confirmedPosition;
            setMapError(geocodeError.message || 'The pin location could not be converted into an address.');
            setLoadStatus('ready');
          }
        };

        placeAutocomplete = new placesLibrary.PlaceAutocompleteElement();
        placeAutocomplete.id = searchId;
        placeAutocomplete.placeholder = initialPosition
          ? 'Search to change the vendor location'
          : 'Search for an address or business in Malaysia';
        placeAutocomplete.includedRegionCodes = ['my'];
        placeAutocomplete.className = 'vendor-place-autocomplete';
        placeAutocomplete.style.colorScheme = 'light';
        placeAutocomplete.setAttribute('aria-describedby', helpId);
        placeAutocomplete.disabled = disabledState.current;
        placeAutocomplete.toggleAttribute('disabled', disabledState.current);
        autocompleteElement.current = placeAutocomplete;

        handlePlaceSelection = async ({ placePrediction }) => {
          try {
            setLoadStatus('resolving');
            setSearchError('');
            setMapError('');

            const place = placePrediction.toPlace();
            await place.fetchFields({
              fields: [
                'id',
                'displayName',
                'formattedAddress',
                'location',
                'viewport',
                'addressComponents',
              ],
            });

            if (isDisposed) return;

            const position = toPosition(place.location);
            if (!position || !place.formattedAddress) {
              throw new Error('Choose a result with a complete address and map location.');
            }

            marker.position = place.location;
            marker.title = `${place.displayName || 'Vendor location'}. Drag the pin to fine-tune the address.`;

            if (place.viewport) {
              map.fitBounds(place.viewport, 48);
            } else {
              map.setCenter(position);
              map.setZoom(17);
            }

            applyLocation({
              address: place.formattedAddress,
              position,
              placeId: place.id,
              addressComponents: place.addressComponents,
            });
            setLoadStatus('ready');
          } catch (selectionError) {
            if (isDisposed) return;
            marker.position = confirmedPosition;
            setMapError(selectionError.message || 'That location could not be selected. Please try another result.');
            setLoadStatus('ready');
          }
        };

        handleAutocompleteError = () => {
          if (isDisposed) return;
          setSearchError(
            'Address suggestions could not be loaded. Enable Places API (New), confirm billing is active, and allow this website in the API key restrictions.'
          );
          setLoadStatus('ready');
        };

        placeAutocomplete.addEventListener('gmp-select', handlePlaceSelection);
        placeAutocomplete.addEventListener('gmp-error', handleAutocompleteError);
        autocompleteContainer.replaceChildren(placeAutocomplete);

        mapListeners.push(
          marker.addListener('dragend', () => {
            void reverseGeocode(toPosition(marker.position));
          })
        );
        mapListeners.push(
          map.addListener('click', (event) => {
            const position = toPosition(event.latLng);
            if (!position) return;
            marker.position = position;
            map.panTo(position);
            void reverseGeocode(position);
          })
        );

        setLoadStatus('ready');
      } catch (initializationError) {
        if (isDisposed) return;
        setMapError(initializationError.message || 'Google Maps could not be initialized.');
        setLoadStatus('error');
      }
    };

    void initialize();

    return () => {
      isDisposed = true;
      mapListeners.forEach((listener) => listener.remove());
      if (placeAutocomplete) {
        if (handlePlaceSelection) {
          placeAutocomplete.removeEventListener('gmp-select', handlePlaceSelection);
        }
        if (handleAutocompleteError) {
          placeAutocomplete.removeEventListener('gmp-error', handleAutocompleteError);
        }
        placeAutocomplete.remove();
      }
      if (autocompleteElement.current === placeAutocomplete) autocompleteElement.current = null;
      if (marker) marker.map = null;
    };
  }, [helpId, initialLocation, onChange, onStateDetected, searchId]);

  useEffect(() => {
    disabledState.current = disabled;
    if (!autocompleteElement.current) return;
    autocompleteElement.current.disabled = disabled;
    autocompleteElement.current.toggleAttribute('disabled', disabled);
  }, [disabled]);

  const hasSelection = hasValidVendorLocation(value);
  const isBusy = loadStatus === 'loading' || loadStatus === 'resolving';

  return (
    <div className="space-y-3">
      <div>
        <label htmlFor={searchId} className="block text-sm font-medium text-surface-900">
          Search Vendor Location <span className="text-red-500" aria-hidden="true">*</span>
        </label>
        <p id={helpId} className="mt-1 text-xs leading-5 text-surface-500">
          Type an address or business name, then choose a suggestion to confirm its exact location.
        </p>
      </div>

      {loadStatus === 'configuration' ? (
        <div className="rounded-xl border border-amber-300 bg-amber-50 p-4" role="alert">
          <div className="flex items-start gap-3">
            <svg className="mt-0.5 h-5 w-5 shrink-0 text-amber-700" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M12 9v4m0 4h.01" strokeLinecap="round" />
              <path d="M10.3 3.8 2.6 17.1A2 2 0 0 0 4.3 20h15.4a2 2 0 0 0 1.7-2.9L13.7 3.8a2 2 0 0 0-3.4 0Z" strokeLinejoin="round" />
            </svg>
            <div>
              <p className="text-sm font-semibold text-amber-900">Google Maps setup required</p>
              <p className="mt-1 text-sm leading-5 text-amber-800">
                Enable Maps JavaScript API, Places API (New), and Geocoding API. Then add <code className="rounded bg-amber-100 px-1 py-0.5 text-xs">VITE_GOOGLE_MAPS_API_KEY</code> to <code className="rounded bg-amber-100 px-1 py-0.5 text-xs">web/.env</code> and restart the web app.
              </p>
            </div>
          </div>
        </div>
      ) : (
        <>
          <div className={`relative z-30 min-h-12 rounded-xl ${error ? 'ring-1 ring-red-500' : ''}`}>
            <div
              ref={autocompleteContainerRef}
              className="relative min-h-12 overflow-visible"
              aria-busy={loadStatus === 'loading'}
            />
            {loadStatus === 'loading' && (
              <div className="absolute inset-0 h-12 animate-pulse rounded-xl bg-surface-100" aria-label="Loading location search" />
            )}
          </div>

          {searchError && (
            <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
              {searchError}
            </p>
          )}

          <div className="relative z-0 overflow-hidden rounded-xl border border-surface-200 bg-surface-100">
            <div
              ref={mapContainerRef}
              className="h-72 w-full sm:h-80"
              aria-label="Map for confirming the vendor location"
            />
            {isBusy && (
              <div className="absolute inset-0 flex items-center justify-center bg-white/70 backdrop-blur-[1px]" role="status" aria-live="polite">
                <div className="flex items-center gap-2 rounded-full bg-white px-4 py-2 text-sm font-medium text-surface-700 shadow">
                  <span className="h-4 w-4 animate-spin rounded-full border-2 border-surface-300 border-t-primary-600" aria-hidden="true" />
                  {loadStatus === 'loading' ? 'Loading map...' : 'Confirming address...'}
                </div>
              </div>
            )}
          </div>

          <p className="flex items-start gap-2 text-xs leading-5 text-surface-500">
            <svg className="mt-0.5 h-4 w-4 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <circle cx="12" cy="12" r="9" />
              <path d="M12 11v5m0-9h.01" strokeLinecap="round" />
            </svg>
            After selecting a result, drag the pin or click the map to fine-tune the entrance location.
          </p>
        </>
      )}

      {mapError && (
        <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700" role="alert">
          {mapError}
        </p>
      )}

      {error && (
        <p className="text-xs font-medium text-red-600" role="alert">{error}</p>
      )}

      {hasSelection && (
        <div className="rounded-xl border border-green-200 bg-green-50 p-4" aria-live="polite">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 rounded-full bg-green-100 p-1.5 text-green-700">
              <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="m8 12 2.5 2.5L16 9" strokeLinecap="round" strokeLinejoin="round" />
                <circle cx="12" cy="12" r="9" />
              </svg>
            </div>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-green-900">Location confirmed</p>
              <p className="mt-1 break-words text-sm leading-5 text-green-800">{value.address_line}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function toCoordinate(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

export function hasValidVendorLocation(location) {
  const latitude = toCoordinate(location?.latitude);
  const longitude = toCoordinate(location?.longitude);

  return Boolean(
    location?.address_line?.trim()
    && latitude !== null
    && longitude !== null
    && latitude >= -90
    && latitude <= 90
    && longitude >= -180
    && longitude <= 180
    && !(latitude === 0 && longitude === 0)
  );
}

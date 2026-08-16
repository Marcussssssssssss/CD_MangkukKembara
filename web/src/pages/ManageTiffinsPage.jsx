import TiffinsManager from '../features/tiffins/TiffinsManager';

/**
 * Manage Heritage Tiffins — module dashboard.
 *
 * This is the central workspace for UC500. From here the admin will:
 *  - View all heritage tiffin editions
 *  - Add new tiffin editions
 *  - Edit existing editions
 *  - Deactivate editions
 */
export default function ManageTiffinsPage() {
  return <TiffinsManager />;
}

import Modal from '../../../components/Modal';

export default function VendorDetails({ vendor, isOpen, onClose, onEdit }) {
  if (!vendor) return null;

  const statusColors = {
    active: 'bg-green-100 text-green-700',
    pending: 'bg-yellow-100 text-yellow-700',
    inactive: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);
  
  const formatTime = (timeStr) => {
    if (!timeStr) return '';
    // timeStr is usually HH:MM:SS
    const [h, m] = timeStr.split(':');
    const d = new Date();
    d.setHours(parseInt(h, 10));
    d.setMinutes(parseInt(m, 10));
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  // Ensure hours are sorted by day_of_week
  const sortedHours = [...(vendor.vendor_operating_hours || [])].sort((a, b) => a.day_of_week - b.day_of_week);

  return (
    <Modal open={isOpen} onClose={onClose} title="Vendor Details" size="xl">
      <div className="flex flex-col md:flex-row">
        {/* Left Side: Image & Map placeholder */}
        <div className="w-full md:w-1/3 shrink-0 flex flex-col border-r border-surface-200">
          <div className="aspect-video md:aspect-square w-full bg-surface-100">
            {vendor.cover_image_url ? (
              <img 
                src={vendor.cover_image_url} 
                alt={vendor.vendor_name}
                className="h-full w-full object-cover"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-primary-100 to-surface-200">
                <span className="text-sm font-medium text-surface-400">No Image</span>
              </div>
            )}
          </div>
          
          <div className="p-6 bg-surface-50 flex-1">
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-3">Operating Hours</h4>
            <div className="space-y-2 text-sm text-surface-700">
              {sortedHours.length > 0 ? sortedHours.map((oh) => (
                <div key={oh.day_of_week} className="flex justify-between">
                  <span className="font-medium text-surface-900">{DAYS[oh.day_of_week]}</span>
                  <span>{oh.is_closed ? 'Closed' : `${formatTime(oh.opening_time)} - ${formatTime(oh.closing_time)}`}</span>
                </div>
              )) : (
                <p className="italic text-surface-500">Not specified.</p>
              )}
            </div>
          </div>
        </div>

        {/* Right Side: Details */}
        <div className="flex-1 overflow-y-auto p-6 md:max-h-[80vh]">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h3 className="text-2xl font-bold text-surface-900">{vendor.vendor_name}</h3>
              <p className="text-sm font-medium text-primary-600 mt-1 capitalize">{vendor.business_type.replace('_', ' ')}</p>
            </div>
            <span className={`shrink-0 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[vendor.participation_status] || 'bg-surface-100 text-surface-700'}`}>
              {getStatusDisplay(vendor.participation_status)}
            </span>
          </div>

          <div className="mt-6 space-y-8">
            {/* Description */}
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Description</h4>
              <p className="mt-1 text-sm text-surface-700">{vendor.description || 'No description provided.'}</p>
            </div>

            {/* Location & Contact */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Contact Information</h4>
                <div className="mt-2 space-y-1 text-sm text-surface-700">
                  <p><span className="font-medium text-surface-900">Person:</span> {vendor.contact_person || 'N/A'}</p>
                  <p><span className="font-medium text-surface-900">Phone:</span> {vendor.contact_number || 'N/A'}</p>
                  <p><span className="font-medium text-surface-900">Email:</span> {vendor.email || 'N/A'}</p>
                </div>
              </div>
              
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Location</h4>
                <div className="mt-2 space-y-1 text-sm text-surface-700">
                  <p className="font-medium text-surface-900">{vendor.states?.state_name}</p>
                  <p className="whitespace-pre-wrap">{vendor.address_line}</p>
                  <p className="text-xs text-surface-500 font-mono mt-1">Lat: {vendor.latitude}, Lng: {vendor.longitude}</p>
                </div>
              </div>
            </div>

            {/* Heritage Foods */}
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Heritage Foods</h4>
              <div className="mt-2 flex flex-wrap gap-2">
                {vendor.vendor_foods && vendor.vendor_foods.length > 0 ? (
                  vendor.vendor_foods.map((vf) => (
                    <span key={vf.heritage_foods.heritage_food_id} className="inline-flex items-center rounded-md bg-orange-50 px-2 py-1 text-xs font-medium text-orange-700 ring-1 ring-inset ring-orange-700/10">
                      {vf.heritage_foods.food_name}
                    </span>
                  ))
                ) : (
                  <p className="text-sm text-surface-500 italic">No heritage foods associated.</p>
                )}
              </div>
            </div>

            {/* Associated Tiffins */}
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Associated Tiffins</h4>
              <div className="mt-2">
                {vendor.vendor_tiffins && vendor.vendor_tiffins.length > 0 ? (
                  <ul className="divide-y divide-surface-100 rounded-lg border border-surface-200">
                    {vendor.vendor_tiffins.map((vt) => (
                      <li key={vt.heritage_tiffins.heritage_tiffin_id} className="flex items-center justify-between p-3 text-sm">
                        <span className="font-medium text-surface-900">{vt.heritage_tiffins.edition_name}</span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-surface-500 italic">No tiffins associated.</p>
                )}
              </div>
            </div>

          </div>

          <div className="mt-8 flex justify-end gap-3 border-t border-surface-100 pt-4">
            <button
              onClick={onClose}
              className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
            >
              Close
            </button>
            <button
              onClick={() => onEdit(vendor)}
              className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
            >
              Edit
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
}

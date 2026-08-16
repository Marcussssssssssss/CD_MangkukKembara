import PageHeader from '../../../components/PageHeader';

export default function VendorDashboard({
  vendors,
  searchQuery,
  onSearchChange,
  onCreate,
  onView,
  onEdit,
  onDeactivate,
}) {
  const statusColors = {
    active: 'bg-green-100 text-green-700',
    pending: 'bg-yellow-100 text-yellow-700',
    inactive: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);

  return (
    <div className="p-6 sm:p-8">
      <PageHeader
        title="Manage Heritage Food Vendors"
        description="View, create, edit, and deactivate vendor information."
        actions={
          <button
            onClick={onCreate}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-700"
          >
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Add New Vendor
          </button>
        }
      />

      {/* Toolbar */}
      <div className="mt-8 mb-6 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:max-w-md">
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-surface-400"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            type="text"
            placeholder="Search vendors..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="w-full rounded-lg border border-surface-200 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          />
        </div>
      </div>

      {/* Table Area */}
      <div className="overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-surface-600">
            <thead className="bg-surface-50 text-xs uppercase text-surface-500">
              <tr>
                <th scope="col" className="px-6 py-4 font-semibold">Vendor Name</th>
                <th scope="col" className="px-6 py-4 font-semibold">Type</th>
                <th scope="col" className="px-6 py-4 font-semibold">Location</th>
                <th scope="col" className="px-6 py-4 font-semibold">Contact</th>
                <th scope="col" className="px-6 py-4 font-semibold">Available Tiffins</th>
                <th scope="col" className="px-6 py-4 font-semibold">Status</th>
                <th scope="col" className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-100">
              {vendors.length > 0 ? (
                vendors.map((vendor) => {
                  const tiffinsCount = vendor.vendor_tiffins?.length || 0;
                  return (
                    <tr key={vendor.vendor_id} className="hover:bg-surface-50">
                      <td className="px-6 py-4 font-medium text-surface-900">
                        {vendor.vendor_name}
                      </td>
                      <td className="px-6 py-4 capitalize">
                        {vendor.business_type.replace('_', ' ')}
                      </td>
                      <td className="px-6 py-4">
                        {vendor.states?.state_name || 'N/A'}
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-surface-900">{vendor.contact_person}</div>
                        <div className="text-xs text-surface-500">{vendor.contact_number}</div>
                      </td>
                      <td className="px-6 py-4">
                        {tiffinsCount} Edition(s)
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[vendor.participation_status] || 'bg-surface-100 text-surface-700'}`}>
                          {getStatusDisplay(vendor.participation_status)}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex justify-end gap-3">
                          <button
                            onClick={() => onView(vendor)}
                            className="text-primary-600 hover:text-primary-700 font-medium"
                          >
                            View
                          </button>
                          <button
                            onClick={() => onEdit(vendor)}
                            className="text-surface-600 hover:text-surface-900 font-medium"
                          >
                            Edit
                          </button>
                          {vendor.participation_status !== 'inactive' && (
                            <button
                              onClick={() => onDeactivate(vendor)}
                              className="text-red-600 hover:text-red-700 font-medium"
                            >
                              Deactivate
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan="7" className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center justify-center text-surface-500">
                      <svg className="mb-4 h-8 w-8 text-surface-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.999 2.999 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.999 2.999 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72m-13.5 8.65h3.75a.75.75 0 00.75-.75V13.5a.75.75 0 00-.75-.75H6.75a.75.75 0 00-.75.75v3.75c0 .415.336.75.75.75z" />
                      </svg>
                      <h3 className="text-sm font-medium text-surface-900">No vendors found</h3>
                      <p className="mt-1 text-sm text-surface-500">
                        {searchQuery ? 'Try adjusting your search query.' : 'Get started by creating a new heritage food vendor.'}
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

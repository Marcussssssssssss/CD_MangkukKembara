import PageHeader from '../../../components/PageHeader';

export default function CampaignDashboard({
  campaigns,
  searchQuery,
  onSearchChange,
  onCreate,
  onView,
  onEdit,
  onDeactivate,
}) {
  const statusColors = {
    draft: 'bg-surface-100 text-surface-700',
    open_submission: 'bg-blue-100 text-blue-700',
    voting: 'bg-purple-100 text-purple-700',
    completed: 'bg-green-100 text-green-700',
    cancelled: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());

  return (
    <div className="p-6 sm:p-8">
      <PageHeader
        title="Manage Heritage Community Campaigns"
        description="View existing artwork design campaigns."
        actions={
          <button
            onClick={onCreate}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-700"
          >
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Add New Campaign
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
            placeholder="Search campaigns..."
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
                <th scope="col" className="px-6 py-4 font-semibold">Campaign Title</th>
                <th scope="col" className="px-6 py-4 font-semibold">Description Summary</th>
                <th scope="col" className="px-6 py-4 font-semibold">Submission Period</th>
                <th scope="col" className="px-6 py-4 font-semibold">Status</th>
                <th scope="col" className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-100">
              {campaigns.length > 0 ? (
                campaigns.map((campaign) => {
                  const startDate = new Date(campaign.submission_start_at).toLocaleDateString();
                  const endDate = new Date(campaign.submission_end_at).toLocaleDateString();

                  return (
                    <tr key={campaign.artwork_campaign_id} className="hover:bg-surface-50">
                      <td className="px-6 py-4 font-medium text-surface-900">
                        {campaign.campaign_title}
                      </td>
                      <td className="px-6 py-4 max-w-xs truncate">
                        {campaign.description || 'No description'}
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-surface-900">{startDate}</div>
                        <div className="text-xs text-surface-500">to {endDate}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[campaign.status] || 'bg-surface-100 text-surface-700'}`}>
                          {getStatusDisplay(campaign.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex justify-end gap-3">
                          <button
                            onClick={() => onView(campaign)}
                            className="text-primary-600 hover:text-primary-700 font-medium"
                          >
                            View
                          </button>
                          {campaign.status !== 'completed' && campaign.status !== 'cancelled' && (
                            <>
                              <button
                                onClick={() => onEdit(campaign)}
                                className="text-blue-600 hover:text-blue-700 font-medium"
                              >
                                Edit
                              </button>
                              <button
                                onClick={() => onDeactivate(campaign)}
                                className="text-red-600 hover:text-red-700 font-medium"
                              >
                                Deactivate
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan="6" className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center justify-center text-surface-500">
                      <svg className="mb-4 h-8 w-8 text-surface-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                      </svg>
                      <h3 className="text-sm font-medium text-surface-900">No campaigns found</h3>
                      <p className="mt-1 text-sm text-surface-500">
                        {searchQuery ? 'Try adjusting your search query.' : 'Get started by creating a new artwork campaign.'}
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

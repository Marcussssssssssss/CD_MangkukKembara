import PageHeader from '../../../components/PageHeader';

export default function VotingSessionDashboard({
  sessions,
  onCreate,
  onView
}) {
  const statusColors = {
    scheduled: 'bg-yellow-100 text-yellow-800',
    active: 'bg-green-100 text-green-700',
    closed: 'bg-surface-100 text-surface-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);

  return (
    <div className="p-6 sm:p-8">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <PageHeader
          title="Manage Voting Sessions"
          description="Create and monitor artwork voting sessions."
        />
        <button
          onClick={onCreate}
          className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
        >
          Create Voting Session
        </button>
      </div>

      {/* Table Area */}
      <div className="mt-8 overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-surface-600">
            <thead className="bg-surface-50 text-xs uppercase text-surface-500">
              <tr>
                <th scope="col" className="px-6 py-4 font-semibold">Session ID</th>
                <th scope="col" className="px-6 py-4 font-semibold">Campaign</th>
                <th scope="col" className="px-6 py-4 font-semibold">Type</th>
                <th scope="col" className="px-6 py-4 font-semibold">Dates</th>
                <th scope="col" className="px-6 py-4 font-semibold">Status</th>
                <th scope="col" className="px-6 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-100">
              {sessions.length > 0 ? (
                sessions.map((session) => {
                  const campaignTitle = session.artwork_campaigns?.campaign_title || 'Unknown';
                  const startDate = new Date(session.voting_start_at).toLocaleString();
                  const endDate = new Date(session.voting_end_at).toLocaleString();

                  return (
                    <tr key={session.artwork_voting_session_id} className="hover:bg-surface-50">
                      <td className="px-6 py-4 font-mono font-medium">{session.artwork_voting_session_id}</td>
                      <td className="px-6 py-4 font-medium text-surface-900">{campaignTitle}</td>
                      <td className="px-6 py-4">
                        <span className="inline-flex rounded-full bg-surface-100 px-2 py-0.5 text-xs font-medium text-surface-700">
                          {session.session_type === 'tie_break' ? 'Tie-Break' : 'Standard'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-surface-900">{startDate}</div>
                        <div className="text-xs text-surface-500 mt-1">to {endDate}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[session.status] || 'bg-surface-100 text-surface-700'}`}>
                          {getStatusDisplay(session.status)}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => onView(session)}
                          className="text-primary-600 hover:text-primary-700 font-medium"
                        >
                          View
                        </button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan="6" className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center justify-center text-surface-500">
                      <svg className="mb-4 h-8 w-8 text-surface-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2.25m0 0v2.25m0-2.25h2.25m-2.25 0H9.75M12 21a9 9 0 100-18 9 9 0 000 18z" />
                      </svg>
                      <h3 className="text-sm font-medium text-surface-900">No voting sessions found</h3>
                      <p className="mt-1 text-sm text-surface-500">
                        Get started by creating a new voting session.
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

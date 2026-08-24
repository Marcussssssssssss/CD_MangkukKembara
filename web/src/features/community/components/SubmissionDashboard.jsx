import { useMemo, useState } from 'react';
import PageHeader from '../../../components/PageHeader';

function SortableHeader({ column, sort, onSort, children }) {
  const active = sort.column === column;
  const ariaSort = !active ? 'none' : sort.direction === 'asc' ? 'ascending' : 'descending';
  return (
    <th scope="col" aria-sort={ariaSort} className="p-0 font-semibold">
      <button type="button" onClick={() => onSort(column)} className="flex w-full items-center gap-1.5 px-6 py-4 text-left uppercase hover:bg-surface-100 hover:text-primary-600">
        {children}
        <span className={active ? 'text-primary-600' : 'text-surface-300'} aria-hidden="true">{active ? (sort.direction === 'asc' ? '↑' : '↓') : '↕'}</span>
      </button>
    </th>
  );
}

export default function SubmissionDashboard({
  submissions,
  filterStatus,
  onFilterChange,
  onView,
  onApprove,
  onReject,
}) {
  const [sort, setSort] = useState({ column: null, direction: null });
  const statusColors = {
    pending: 'bg-yellow-100 text-yellow-800',
    approved: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);

  const sortedSubmissions = useMemo(() => {
    const result = [...submissions];
    if (!sort.column) {
      const statusOrder = { pending: 0, approved: 1, rejected: 2 };
      return result.sort((a, b) => {
        const statusDifference = (statusOrder[a.review_status] ?? 3)
          - (statusOrder[b.review_status] ?? 3);
        if (statusDifference !== 0) return statusDifference;
        return String(a.artwork_submission_id).localeCompare(
          String(b.artwork_submission_id), undefined, { numeric: true },
        );
      });
    }

    const values = {
      artwork: submission => submission.artwork_title || '',
      campaign: submission => submission.artwork_campaigns?.campaign_title || '',
      submitted: submission => new Date(submission.submitted_at).getTime(),
      status: submission => submission.review_status || '',
    };
    const valueFor = values[sort.column];
    const multiplier = sort.direction === 'asc' ? 1 : -1;
    return result.sort((a, b) => {
      const aValue = valueFor(a);
      const bValue = valueFor(b);
      if (typeof aValue === 'number') return (aValue - bValue) * multiplier;
      return String(aValue).localeCompare(String(bValue), undefined, { sensitivity: 'base' }) * multiplier;
    });
  }, [submissions, sort]);

  const changeSort = (column) => {
    setSort(current => {
      if (current.column !== column) return { column, direction: 'asc' };
      if (current.direction === 'asc') return { column, direction: 'desc' };
      return { column: null, direction: null };
    });
  };

  return (
    <div className="p-6 sm:p-8">
      <PageHeader
        title="Review Artwork Submissions"
      />

      {/* Toolbar */}
      <div className="mt-8 mb-6 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="w-full sm:w-auto flex items-center gap-2">
          <label htmlFor="statusFilter" className="text-sm font-medium text-surface-700">Filter Status:</label>
          <select
            id="statusFilter"
            value={filterStatus}
            onChange={(e) => onFilterChange(e.target.value)}
            className="rounded-lg border border-surface-200 bg-white py-2 pl-3 pr-8 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          >
            <option value="all">All Submissions</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>
      </div>

      {/* Table Area */}
      <div className="overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
        <div className="overflow-hidden">
          <table className="w-full text-left text-sm text-surface-600">
            <thead className="bg-surface-50 text-xs uppercase text-surface-500">
              <tr>
                <th scope="col" className="px-6 py-4 font-semibold">Artwork Image</th>
                <SortableHeader column="artwork" sort={sort} onSort={changeSort}>Title &amp; Submitter</SortableHeader>
                <SortableHeader column="campaign" sort={sort} onSort={changeSort}>Campaign</SortableHeader>
                <SortableHeader column="submitted" sort={sort} onSort={changeSort}>Date Submitted</SortableHeader>
                <SortableHeader column="status" sort={sort} onSort={changeSort}>Status</SortableHeader>
                <th scope="col" className="w-28 px-3 py-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-100">
              {sortedSubmissions.length > 0 ? (
                sortedSubmissions.map((sub) => {
                  const submitter = sub.profiles?.display_name || sub.profile_id;
                  const campaign = sub.artwork_campaigns;
                  const campaignTitle = campaign?.campaign_title || 'Unknown Campaign';

                  const date = new Date(sub.submitted_at).toLocaleDateString();

                  return (
                    <tr
                      key={sub.artwork_submission_id}
                      onClick={() => onView(sub)}
                      className="cursor-pointer transition-transform duration-150 hover:relative hover:z-10 hover:scale-[1.01] hover:bg-surface-50 hover:shadow-sm"
                    >
                      <td className="px-6 py-4">
                        <div className="h-16 w-16 overflow-hidden rounded-lg bg-surface-100 border border-surface-200">
                          {sub.artwork_file_url ? (
                            <img src={sub.artwork_file_url} alt={sub.artwork_title} className="h-full w-full object-cover" />
                          ) : (
                            <span className="flex h-full items-center justify-center text-xs text-surface-400">No Img</span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-medium text-surface-900">{sub.artwork_title}</div>
                        <div className="text-xs text-surface-500 mt-1">by {submitter}</div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-surface-900">{campaignTitle}</div>
                        {(campaign?.states?.state_name || campaign?.state_id) && (
                          <div className="mt-1 text-xs text-surface-500">
                            {campaign.states?.state_name || campaign.state_id}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {date}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[sub.review_status] || 'bg-surface-100 text-surface-700'}`}>
                          {getStatusDisplay(sub.review_status)}
                        </span>
                      </td>
                      <td className="w-28 px-3 py-4 text-right">
                        <div className="ml-auto grid w-28 grid-cols-2 items-center gap-2">
                          {(sub.review_status === 'pending' || sub.review_status === 'rejected') && (
                            <button
                              onClick={(event) => { event.stopPropagation(); onApprove(sub); }}
                              className="font-medium text-green-600 hover:text-green-700"
                            >
                              Approve
                            </button>
                          )}
                          {sub.review_status === 'approved' && <span aria-hidden="true" />}
                          {sub.review_status === 'pending' && (
                            <button
                              onClick={(event) => { event.stopPropagation(); onReject(sub); }}
                              className="font-medium text-red-600 hover:text-red-700"
                            >
                              Reject
                            </button>
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
                      <h3 className="text-sm font-medium text-surface-900">No submissions found</h3>
                      <p className="mt-1 text-sm text-surface-500">
                        There are no submissions matching your filter criteria.
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

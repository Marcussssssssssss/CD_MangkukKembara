import { useEffect, useState } from 'react';
import Modal from '../../../components/Modal';

const asVoteCount = (value) => Number(value) || 0;

const asTimestamp = (value) => {
  const timestamp = value ? new Date(value).getTime() : Number.NaN;
  return Number.isNaN(timestamp) ? Number.MAX_SAFE_INTEGER : timestamp;
};

export default function VotingSessionDetails({
  session,
  isOpen,
  onClose,
  onActivate,
  onCloseVoting,
  onFinalise,
  onResolveTie,
  hasTieBreakChild = false
}) {
  const [currentTime, setCurrentTime] = useState(Date.now);

  useEffect(() => {
    const timer = window.setInterval(() => setCurrentTime(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  if (!session) return null;

  const statusColors = {
    scheduled: 'bg-yellow-100 text-yellow-800',
    active: 'bg-green-100 text-green-700',
    closed: 'bg-surface-100 text-surface-700',
  };

  const getStatusDisplay = (status) => status
    ? status.charAt(0).toUpperCase() + status.slice(1)
    : 'Unknown';

  const isTieBreak = session.session_type === 'tie_break';
  const isClosed = session.status === 'closed';
  const startTime = new Date(session.voting_start_at).getTime();
  const endTime = new Date(session.voting_end_at).getTime();
  const campaignTitle = session.artwork_campaigns?.campaign_title || 'Unknown Campaign';
  const campaignStatus = session.artwork_campaigns?.status;
  const campaignCanBeResolved = !campaignStatus || campaignStatus === 'active';

  const entries = Array.isArray(session.artwork_voting_entries)
    ? session.artwork_voting_entries
    : [];

  // Display order is deterministic for equal scores, while rank changes only
  // when the vote count changes (dense ranking: 1, 1, 2 rather than 1, 1, 3).
  const sortedEntries = [...entries].sort((left, right) => {
    const voteDifference = asVoteCount(right.vote_count) - asVoteCount(left.vote_count);
    if (voteDifference !== 0) return voteDifference;

    const publishedDifference = asTimestamp(left.published_at) - asTimestamp(right.published_at);
    if (publishedDifference !== 0) return publishedDifference;

    return left.artwork_voting_entry_id.localeCompare(right.artwork_voting_entry_id);
  });

  const distinctVoteCounts = [...new Set(
    sortedEntries.map(entry => asVoteCount(entry.vote_count))
  )];

  const rankedEntries = sortedEntries.map((entry, index) => {
    const voteCount = asVoteCount(entry.vote_count);

    return {
      ...entry,
      voteCount,
      rank: distinctVoteCounts.indexOf(voteCount) + 1,
      displayOrder: index + 1
    };
  });

  const highestVotes = rankedEntries[0]?.voteCount;
  const topScorers = highestVotes === undefined
    ? []
    : rankedEntries.filter(entry => entry.voteCount === highestVotes);
  const hasTopTie = topScorers.length > 1;
  const hasUniqueTop = topScorers.length === 1;
  const isTerminalSession = !hasTieBreakChild;

  const canActivate = session.status === 'scheduled' && currentTime >= startTime && currentTime < endTime;
  const canCloseVoting = !isClosed && currentTime >= endTime;
  const canCreateTieBreak = isClosed && isTerminalSession && hasTopTie && campaignCanBeResolved;
  const canFinalise = isClosed && isTerminalSession && hasUniqueTop && campaignCanBeResolved;

  const startDate = new Date(session.voting_start_at).toLocaleString();
  const endDate = new Date(session.voting_end_at).toLocaleString();

  return (
    <Modal open={isOpen} onClose={onClose} title="Voting Session Details" size="4xl">
      <div className="flex flex-col p-6 max-h-[85vh] overflow-y-auto">
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 border-b border-surface-200 pb-4">
          <div>
            <div className="flex items-center gap-3">
              <h3 className="text-2xl font-bold text-surface-900">{session.artwork_voting_session_id}</h3>
              <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${isTieBreak ? 'bg-purple-100 text-purple-800' : 'bg-surface-100 text-surface-700'}`}>
                {isTieBreak ? 'Tie-Break Session' : 'Standard Session'}
              </span>
            </div>
            <p className="text-sm font-medium text-surface-500 mt-2">
              Campaign: <span className="text-surface-900">{campaignTitle}</span>
            </p>
            {isTieBreak && session.parent_voting_session_id && (
              <p className="text-sm font-medium text-surface-500 mt-1">
                Parent Session: <span className="font-mono text-surface-900">{session.parent_voting_session_id}</span>
              </p>
            )}
          </div>
          <span className={`shrink-0 inline-flex items-center rounded-full px-3 py-1 text-sm font-semibold ${statusColors[session.status] || 'bg-surface-100 text-surface-700'}`}>
            {getStatusDisplay(session.status)}
          </span>
        </div>

        <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-4 bg-surface-50 p-4 rounded-xl border border-surface-200">
          <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Voting Start</h4>
            <p className="mt-1 text-sm font-medium text-surface-900">{startDate}</p>
          </div>
          <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Voting End</h4>
            <p className="mt-1 text-sm font-medium text-surface-900">{endDate}</p>
          </div>
        </div>

        <div className="mt-8">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h4 className="text-sm font-bold text-surface-900">
              {isClosed ? 'Final Results' : `Participating Artworks (${rankedEntries.length})`}
            </h4>
            {isClosed && hasTieBreakChild && (
              <span className="inline-flex rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-semibold text-purple-800">
                Tie-break already created
              </span>
            )}
            {isClosed && isTerminalSession && hasTopTie && (
              <span className="inline-flex rounded-full bg-yellow-100 px-2.5 py-0.5 text-xs font-semibold text-yellow-800">
                Top result tied
              </span>
            )}
            {isClosed && isTerminalSession && hasUniqueTop && (
              <span className="inline-flex rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-semibold text-green-800">
                Unique top result
              </span>
            )}
          </div>

          {rankedEntries.length > 0 ? (
            <div className="overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-surface-600">
                  <thead className="bg-surface-50 text-xs uppercase text-surface-500 border-b border-surface-200">
                    <tr>
                      {isClosed && <th scope="col" className="px-6 py-4 font-semibold w-20">Rank</th>}
                      <th scope="col" className="px-6 py-4 font-semibold">Artwork</th>
                      <th scope="col" className="px-6 py-4 font-semibold text-center w-24">Display</th>
                      <th scope="col" className="px-6 py-4 font-semibold text-right">Votes</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-surface-100">
                    {rankedEntries.map(entry => {
                      const artwork = entry.artwork_submissions;
                      const isTop = isClosed && entry.rank === 1;
                      const isWinnerCandidate = isTop && hasUniqueTop;
                      const isTiedTop = isTop && hasTopTie;

                      return (
                        <tr
                          key={entry.artwork_voting_entry_id}
                          className={`hover:bg-surface-50 ${isWinnerCandidate ? 'bg-green-50' : (isTiedTop ? 'bg-yellow-50' : '')}`}
                        >
                          {isClosed && (
                            <td className="px-6 py-4 font-semibold text-surface-900">#{entry.rank}</td>
                          )}
                          <td className="px-6 py-4">
                            <div className="flex items-center gap-4">
                              <div className={`h-12 w-12 shrink-0 overflow-hidden rounded bg-surface-100 border ${isWinnerCandidate ? 'border-green-400 ring-2 ring-green-100' : 'border-surface-200'}`}>
                                {artwork?.artwork_file_url ? (
                                  <img src={artwork.artwork_file_url} alt="" className="h-full w-full object-cover" />
                                ) : (
                                  <span className="flex h-full items-center justify-center text-[10px] text-surface-400">No Img</span>
                                )}
                              </div>
                              <div className="min-w-0">
                                <p className="font-medium text-surface-900 truncate">
                                  {artwork?.artwork_title || 'Unknown Title'}
                                  {isWinnerCandidate && (
                                    <span className="ml-2 inline-flex items-center rounded bg-green-100 px-2 py-0.5 text-[10px] font-bold text-green-700">TOP</span>
                                  )}
                                  {isTiedTop && (
                                    <span className="ml-2 inline-flex items-center rounded bg-yellow-100 px-2 py-0.5 text-[10px] font-bold text-yellow-700">TIED</span>
                                  )}
                                </p>
                                <p className="text-xs text-surface-500 truncate mt-0.5">
                                  by {artwork?.profiles?.display_name || 'Unknown'}
                                </p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center text-xs text-surface-500">#{entry.displayOrder}</td>
                          <td className="px-6 py-4 text-right">
                            <span className={`inline-flex items-center justify-center rounded-full px-3 py-1 text-sm font-bold ring-1 ring-inset ${isWinnerCandidate ? 'bg-green-100 text-green-700 ring-green-600/20' : (isTiedTop ? 'bg-yellow-100 text-yellow-700 ring-yellow-600/20' : 'bg-primary-50 text-primary-700 ring-primary-600/20')}`}>
                              {entry.voteCount}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          ) : (
            <div className="rounded-lg border border-surface-200 border-dashed p-8 text-center bg-surface-50">
              <p className="text-sm text-surface-500">No entries found for this voting session.</p>
            </div>
          )}
        </div>

        <div className="mt-8 flex flex-wrap justify-end gap-3 border-t border-surface-100 pt-4">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
          >
            Close Details
          </button>

          {canActivate && (
            <button
              onClick={() => onActivate(session)}
              className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
            >
              Activate Voting
            </button>
          )}

          {canCloseVoting && (
            <button
              onClick={() => onCloseVoting(session)}
              className="rounded-lg bg-surface-700 px-4 py-2 text-sm font-medium text-white hover:bg-surface-800"
            >
              Close Voting
            </button>
          )}

          {canCreateTieBreak && (
            <button
              onClick={() => onResolveTie(session.artwork_voting_session_id, campaignTitle)}
              className="rounded-lg bg-purple-600 px-4 py-2 text-sm font-medium text-white hover:bg-purple-700"
            >
              Create Tie-Break
            </button>
          )}

          {canFinalise && (
            <button
              onClick={() => onFinalise(session)}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Finalise Voting Session
            </button>
          )}
        </div>
      </div>
    </Modal>
  );
}

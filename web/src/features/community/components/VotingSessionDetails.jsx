import Modal from '../../../components/Modal';

export default function VotingSessionDetails({ session, isOpen, onClose, onFinalise, onResolveTie }) {
  if (!session) return null;

  const statusColors = {
    scheduled: 'bg-yellow-100 text-yellow-800',
    active: 'bg-green-100 text-green-700',
    closed: 'bg-surface-100 text-surface-700',
  };

  const getStatusDisplay = (status) => status.charAt(0).toUpperCase() + status.slice(1);
  const isTieBreak = session.session_type === 'tie_break';

  const startDate = new Date(session.voting_start_at).toLocaleString();
  const endDate = new Date(session.voting_end_at).toLocaleString();
  const campaignTitle = session.artwork_campaigns?.campaign_title || 'Unknown Campaign';

  return (
    <Modal open={isOpen} onClose={onClose} title="Voting Session Details" size="4xl">
      <div className="flex flex-col p-6 max-h-[85vh] overflow-y-auto">
        
        {/* Header Section */}
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 border-b border-surface-200 pb-4">
          <div>
            <div className="flex items-center gap-3">
              <h3 className="text-2xl font-bold text-surface-900">{session.artwork_voting_session_id}</h3>
              {isTieBreak ? (
                <span className="inline-flex rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-semibold text-purple-800">
                  Tie-Break Session
                </span>
              ) : (
                <span className="inline-flex rounded-full bg-surface-100 px-2.5 py-0.5 text-xs font-semibold text-surface-700">
                  Standard Session
                </span>
              )}
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

        {/* Schedule */}
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

        {/* Entries / Results */}
        <div className="mt-8">
          {session.status === 'closed' ? (
            <h4 className="text-sm font-bold text-surface-900 mb-4">Final Results</h4>
          ) : (
            <h4 className="text-sm font-bold text-surface-900 mb-4">Participating Artworks ({session.artwork_voting_entries?.length || 0})</h4>
          )}
          
          {session.artwork_voting_entries && session.artwork_voting_entries.length > 0 ? (
            <div className="space-y-6">
              {Object.entries(
                session.artwork_voting_entries.reduce((acc, entry) => {
                  const catId = entry.artwork_campaign_categories?.artwork_campaign_category_id || entry.artwork_campaign_category_id;
                  const catName = entry.artwork_campaign_categories?.category_name || 'Unknown';
                  if (!acc[catId]) acc[catId] = { categoryName: catName, entries: [] };
                  acc[catId].entries.push(entry);
                  return acc;
                }, {})
              ).map(([categoryId, { categoryName, entries }]) => {
                
                // Sort descending by vote count
                const sortedEntries = [...entries].sort((a, b) => b.vote_count - a.vote_count);
                const highestVotes = sortedEntries[0]?.vote_count || 0;
                
                // Identify tie
                const topScorers = sortedEntries.filter(e => e.vote_count === highestVotes);
                const isTied = highestVotes > 0 && topScorers.length > 1;
                const hasWinner = highestVotes > 0 && topScorers.length === 1;

                return (
                  <div key={categoryId} className="overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
                    <div className="bg-surface-50 px-6 py-3 border-b border-surface-200 flex items-center justify-between">
                      <h5 className="font-semibold text-surface-900">Voting Entries</h5>
                      <div className="flex items-center gap-3">
                        {session.status === 'closed' && (
                          isTied ? (
                            <>
                              <span className="inline-flex rounded-full bg-yellow-100 px-2.5 py-0.5 text-xs font-semibold text-yellow-800">Tied Result (Tie-Break Session Required)</span>
                              <button
                                onClick={() => onResolveTie(session.artwork_voting_session_id, categoryId, campaignTitle)}
                                className="inline-flex items-center rounded-lg bg-purple-100 px-3 py-1 text-xs font-semibold text-purple-700 hover:bg-purple-200"
                              >
                                Create Tie-Break
                              </button>
                            </>
                          ) : hasWinner ? (
                            <span className="inline-flex rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-semibold text-green-800">Clear Winner Found</span>
                          ) : null
                        )}
                      </div>
                    </div>
                    <div className="overflow-x-auto">
                      <table className="w-full text-left text-sm text-surface-600">
                        <thead className="bg-white text-xs uppercase text-surface-500 border-b border-surface-100">
                          <tr>
                            {session.status === 'closed' && <th scope="col" className="px-6 py-4 font-semibold w-16">Rank</th>}
                            <th scope="col" className="px-6 py-4 font-semibold">Artwork</th>
                            <th scope="col" className="px-6 py-4 font-semibold text-right">Votes</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-surface-100">
                          {(() => {
                            let currentRank = 1;
                            let previousVotes = null;
                            
                            return sortedEntries.map((entry, index) => {
                              if (previousVotes !== null && entry.vote_count < previousVotes) {
                                currentRank = index + 1;
                              }
                              previousVotes = entry.vote_count;
                              
                              const artwork = entry.artwork_submissions;
                              const isWinner = session.status === 'closed' && hasWinner && entry.vote_count === highestVotes;
                              const isTiedTop = session.status === 'closed' && isTied && entry.vote_count === highestVotes;
                              
                              return (
                                <tr key={entry.artwork_voting_entry_id} className={`hover:bg-surface-50 ${isWinner ? 'bg-green-50' : (isTiedTop ? 'bg-yellow-50' : '')}`}>
                                  {session.status === 'closed' && (
                                    <td className="px-6 py-4 font-semibold text-surface-900">
                                      #{currentRank}
                                    </td>
                                  )}
                                <td className="px-6 py-4">
                                  <div className="flex items-center gap-4">
                                    <div className={`h-12 w-12 shrink-0 overflow-hidden rounded bg-surface-100 border ${isWinner ? 'border-green-400 ring-2 ring-green-100' : 'border-surface-200'}`}>
                                      {artwork?.artwork_file_url ? (
                                        <img src={artwork.artwork_file_url} alt="" className="h-full w-full object-cover" />
                                      ) : (
                                        <span className="flex h-full items-center justify-center text-[10px] text-surface-400">No Img</span>
                                      )}
                                    </div>
                                    <div className="min-w-0">
                                      <p className="font-medium text-surface-900 truncate">
                                        {artwork?.artwork_title || 'Unknown Title'}
                                        {isWinner && <span className="ml-2 inline-flex items-center rounded bg-green-100 px-2 py-0.5 text-[10px] font-bold text-green-700">WINNER</span>}
                                        {isTiedTop && <span className="ml-2 inline-flex items-center rounded bg-yellow-100 px-2 py-0.5 text-[10px] font-bold text-yellow-700">TIED</span>}
                                      </p>
                                      <p className="text-xs text-surface-500 truncate mt-0.5">by {artwork?.profiles?.display_name || 'Unknown'}</p>
                                    </div>
                                  </div>
                                </td>
                                <td className="px-6 py-4 text-right">
                                  <span className={`inline-flex items-center justify-center rounded-full px-3 py-1 text-sm font-bold ring-1 ring-inset ${isWinner ? 'bg-green-100 text-green-700 ring-green-600/20' : (isTiedTop ? 'bg-yellow-100 text-yellow-700 ring-yellow-600/20' : 'bg-primary-50 text-primary-700 ring-primary-600/20')}`}>
                                    {entry.vote_count}
                                  </span>
                                </td>
                              </tr>
                            );
                          });
                        })()}
                        </tbody>
                      </table>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="rounded-lg border border-surface-200 border-dashed p-8 text-center bg-surface-50">
              <p className="text-sm text-surface-500">No entries found for this voting session.</p>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex justify-end gap-3 border-t border-surface-100 pt-4">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
          >
            Close
          </button>
          
          {session.status !== 'closed' && new Date() > new Date(session.voting_end_at) && (
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

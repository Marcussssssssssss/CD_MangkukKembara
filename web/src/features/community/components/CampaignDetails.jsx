import { useState, useEffect } from 'react';
import Modal from '../../../components/Modal';
import { fetchCampaignWinners } from '../services/communityService';

export default function CampaignDetails({ campaign, isOpen, onClose, onEdit, onComplete, onPromote, onViewWinner }) {
  const [winners, setWinners] = useState([]);
  const [isLoadingWinners, setIsLoadingWinners] = useState(false);

  useEffect(() => {
    if (isOpen && campaign && campaign.status === 'completed') {
      const loadWinners = async () => {
        try {
          setIsLoadingWinners(true);
          const data = await fetchCampaignWinners(campaign.artwork_campaign_id);
          setWinners(data);
        } catch (err) {
          console.error('Failed to load winners:', err);
        } finally {
          setIsLoadingWinners(false);
        }
      };
      loadWinners();
    } else {
      setWinners([]);
    }
  }, [isOpen, campaign]);

  if (!campaign) return null;

  const statusColors = {
    draft: 'bg-surface-100 text-surface-700',
    open_submission: 'bg-blue-100 text-blue-700',
    voting: 'bg-purple-100 text-purple-700',
    completed: 'bg-green-100 text-green-700',
    cancelled: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());

  const startDate = new Date(campaign.submission_start_at).toLocaleString();
  const endDate = new Date(campaign.submission_end_at).toLocaleString();

  return (
    <Modal open={isOpen} onClose={onClose} title="Campaign Details" size="xl">
      <div className="flex flex-col p-6 max-h-[85vh] overflow-y-auto">
        
        {/* Header Section */}
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="text-2xl font-bold text-surface-900">{campaign.campaign_title}</h3>
            <p className="text-sm font-medium text-surface-500 mt-1 font-mono">ID: {campaign.artwork_campaign_id}</p>
          </div>
          <span className={`shrink-0 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[campaign.status] || 'bg-surface-100 text-surface-700'}`}>
            {getStatusDisplay(campaign.status)}
          </span>
        </div>

        <div className="mt-8 space-y-8">
          
          {/* Description */}
          <div>
            <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Description</h4>
            <p className="mt-2 text-sm text-surface-700 whitespace-pre-wrap">
              {campaign.description || 'No description provided.'}
            </p>
          </div>

          {/* Timing Information */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 p-4 rounded-lg bg-surface-50 border border-surface-200">
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Submission Start</h4>
              <p className="mt-1 font-medium text-surface-900">{startDate}</p>
            </div>
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Submission End</h4>
              <p className="mt-1 font-medium text-surface-900">{endDate}</p>
            </div>
          </div>



          {/* Campaign Winners */}
          {campaign.status === 'completed' && (
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Confirmed Winners</h4>
              <div className="mt-3">
                {isLoadingWinners ? (
                  <p className="text-sm text-surface-500 italic">Loading winners...</p>
                ) : winners.length > 0 ? (
                  (() => {
                    const topRankWinners = winners.filter(w => w.final_rank === 1);
                    const isTied = topRankWinners.length > 1;

                    if (isTied) {
                      return (
                        <div className="rounded-xl border border-yellow-200 bg-yellow-50 p-8 text-center">
                          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-yellow-200 mb-4 shadow-sm">
                            <span className="text-yellow-800 font-bold text-xl">TIE</span>
                          </div>
                          <h4 className="text-lg font-bold text-yellow-900 mb-2">Unresolved Tie Detected</h4>
                          <p className="text-sm text-yellow-700 mb-6">
                            This campaign ended in a tie between <span className="font-bold">{topRankWinners.length}</span> designs. No winner can be confirmed yet.
                          </p>
                          <p className="text-sm font-medium text-yellow-800 bg-yellow-100 py-3 px-4 rounded-lg inline-block">
                            Please navigate to the <span className="font-bold uppercase tracking-wider">Voting Sessions</span> tab to resolve this tie.
                          </p>
                        </div>
                      );
                    }

                    const winner = topRankWinners[0];
                    if (!winner) return (
                      <div className="rounded-lg border border-surface-200 border-dashed p-6 text-center bg-surface-50">
                        <p className="text-sm text-surface-500">No confirmed winners found for this campaign.</p>
                      </div>
                    );

                    const submission = winner.artwork_voting_entries?.artwork_submissions;
                    const session = winner.artwork_voting_entries?.artwork_voting_sessions;
                    const isPromoted = !!winner.artwork_id;
                    const resultDate = new Date(winner.announced_at).toLocaleString();

                    return (
                      <div className="overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm">
                        <div className="border-b border-surface-100 bg-surface-50 px-6 py-4 flex items-center justify-between">
                          <h5 className="font-bold text-surface-900">Campaign Winner</h5>
                          <span className="inline-flex rounded-full bg-green-100 px-3 py-1 text-xs font-bold text-green-800 uppercase tracking-wide shadow-sm">Confirmed Winner</span>
                        </div>
                        <div className="p-6 sm:p-8">
                          <div className="flex flex-col sm:flex-row gap-8">
                            <div className="h-40 w-40 shrink-0 overflow-hidden rounded-xl bg-surface-100 border border-surface-200 shadow-sm">
                              {submission?.artwork_file_url ? (
                                <img src={submission.artwork_file_url} alt="" className="h-full w-full object-cover" />
                              ) : (
                                <span className="flex h-full items-center justify-center text-xs text-surface-400">No Img</span>
                              )}
                            </div>
                            <div className="flex-1 min-w-0 flex flex-col justify-between">
                              <div>
                                <h6 className="text-2xl font-bold text-surface-900 truncate">{submission?.artwork_title || 'Unknown'}</h6>
                                <p className="text-base text-surface-500 mt-1">by <span className="text-surface-700 font-medium">{submission?.profiles?.display_name || 'Unknown'}</span></p>
                              </div>
                              <div className="grid grid-cols-2 gap-x-6 gap-y-4 mt-6">
                                <div>
                                  <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider">Final Vote Count</p>
                                  <p className="text-xl font-bold text-primary-600 mt-1">{winner.final_vote_count}</p>
                                </div>
                                <div>
                                  <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider">Winning Session</p>
                                  <p className="text-sm font-semibold text-surface-900 mt-1 uppercase">
                                    {session?.session_type ? session.session_type.replace('_', ' ') : 'Standard'}
                                  </p>
                                </div>
                                <div>
                                  <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider">Result Date</p>
                                  <p className="text-sm font-semibold text-surface-900 mt-1">{resultDate}</p>
                                </div>
                                <div>
                                  <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider">Status</p>
                                  <p className="text-sm font-semibold mt-1">
                                    {isPromoted ? <span className="text-green-600">Promoted ({winner.artwork_id})</span> : <span className="text-surface-900">Pending Promotion</span>}
                                  </p>
                                </div>
                              </div>
                            </div>
                          </div>
                          
                          <div className="mt-8 flex items-center justify-end gap-3 pt-6 border-t border-surface-100">
                            <button
                              onClick={() => onViewWinner(winner)}
                              className="inline-flex items-center rounded-lg bg-surface-100 px-5 py-2.5 text-sm font-bold text-surface-700 hover:bg-surface-200 transition-colors"
                            >
                              View Full Details
                            </button>
                            {!isPromoted && (
                              <button
                                onClick={() => onPromote(winner, submission)}
                                className="inline-flex items-center rounded-lg bg-green-600 px-5 py-2.5 text-sm font-bold text-white hover:bg-green-700 transition-colors shadow-sm"
                              >
                                Promote to Artwork
                              </button>
                            )}
                          </div>
                        </div>
                      </div>
                    );
                  })()
                ) : (
                  <div className="rounded-lg border border-surface-200 border-dashed p-6 text-center bg-surface-50">
                    <p className="text-sm text-surface-500">No confirmed winners found for this campaign.</p>
                  </div>
                )}
              </div>
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
          
          {/* Action Placeholders */}
          {campaign.status !== 'completed' && campaign.status !== 'cancelled' && (
            <>
              <button
                onClick={() => onEdit(campaign)}
                className="rounded-lg bg-surface-800 px-4 py-2 text-sm font-medium text-white hover:bg-surface-900"
              >
                Edit
              </button>
              <button
                onClick={() => onComplete(campaign)}
                className="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
              >
                Complete Campaign
              </button>
            </>
          )}
        </div>
        
      </div>
    </Modal>
  );
}

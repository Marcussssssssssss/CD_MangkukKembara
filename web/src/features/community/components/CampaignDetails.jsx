import { useState, useEffect } from 'react';
import Modal from '../../../components/Modal';
import { fetchCampaignTopVotedArtworks } from '../services/communityService';

const formatDate = (value) => new Intl.DateTimeFormat('en-GB', {
  day: '2-digit', month: '2-digit', year: 'numeric',
}).format(new Date(value));

export default function CampaignDetails({ campaign, isOpen, onClose, onEdit }) {
  const [winners, setWinners] = useState([]);
  const [isLoadingWinners, setIsLoadingWinners] = useState(false);

  useEffect(() => {
    if (!isOpen || !campaign || campaign.status !== 'completed') return undefined;

    let cancelled = false;
    const loadWinners = async () => {
      try {
        setIsLoadingWinners(true);
        const data = await fetchCampaignTopVotedArtworks(campaign.artwork_campaign_id);
        if (!cancelled) setWinners(data);
      } catch (err) {
        console.error('Failed to load winners:', err);
        if (!cancelled) setWinners([]);
      } finally {
        if (!cancelled) setIsLoadingWinners(false);
      }
    };

    loadWinners();
    return () => {
      cancelled = true;
    };
  }, [isOpen, campaign]);

  if (!campaign) return null;

  const statusColors = {
    active: 'bg-blue-100 text-blue-700',
    completed: 'bg-green-100 text-green-700',
    inactive: 'bg-red-100 text-red-700',
  };

  const getStatusDisplay = (status) => status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());

  const startDate = formatDate(campaign.submission_start_at);
  const endDate = formatDate(campaign.submission_end_at);

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
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 p-4 rounded-lg bg-surface-50 border border-surface-200">
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">State</h4>
              <p className="mt-1 font-medium text-surface-900">
                {campaign.states?.state_name || campaign.state_id || 'Unknown State'}
              </p>
              {campaign.states?.state_code && (
                <p className="mt-0.5 text-xs text-surface-500">{campaign.states.state_code}</p>
              )}
            </div>
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
                    return (
                      <div className="grid gap-4 sm:grid-cols-2">
                        {winners.map((winner) => {
                          const submission = winner.artwork_submissions;
                          return (
                            <div key={winner.artwork_voting_entry_id} className="flex gap-4 rounded-xl border border-surface-200 bg-white p-4 shadow-sm">
                              <div className="h-24 w-24 shrink-0 overflow-hidden rounded-lg bg-surface-100">
                                {submission?.artwork_file_url ? <img src={submission.artwork_file_url} alt={submission.artwork_title || 'Winning artwork'} className="h-full w-full object-cover" /> : <span className="flex h-full items-center justify-center text-xs text-surface-400">No image</span>}
                              </div>
                              <div className="min-w-0 self-center">
                                <h5 className="truncate font-bold text-surface-900">{submission?.artwork_title || 'Untitled artwork'}</h5>
                                <p className="mt-2 text-xs font-bold uppercase tracking-wider text-surface-400">Vote Count</p>
                                <p className="text-xl font-bold text-primary-600">{winner.vote_count}</p>
                              </div>
                            </div>
                          );
                        })}
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
          
          {campaign.status === 'active' && (
            <button
              onClick={() => onEdit(campaign)}
              className="rounded-lg bg-surface-800 px-4 py-2 text-sm font-medium text-white hover:bg-surface-900"
            >
              Edit
            </button>
          )}
        </div>
        
      </div>
    </Modal>
  );
}

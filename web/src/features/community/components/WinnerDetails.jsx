import { useState } from 'react';
import Modal from '../../../components/Modal';
import { generateHandoverPDF } from '../utils/pdfGenerator';

export default function WinnerDetails({ winner, isOpen, onClose, onPromote }) {
  const [isGeneratingPDF, setIsGeneratingPDF] = useState(false);
  const [pdfError, setPdfError] = useState(null);

  if (!winner) return null;

  const campaign = winner.artwork_campaigns;
  const category = winner.artwork_campaign_categories;
  const entry = winner.artwork_voting_entries;
  const submission = entry?.artwork_submissions;
  const session = entry?.artwork_voting_sessions;
  const artwork = winner.artworks;

  const announcedDate = new Date(winner.announced_at).toLocaleString();

  const handleDownloadPDF = async () => {
    try {
      setIsGeneratingPDF(true);
      setPdfError(null);
      await generateHandoverPDF({ campaign, category, submission, session, winner });
    } catch (err) {
      setPdfError(err.message || 'Failed to generate PDF.');
    } finally {
      setIsGeneratingPDF(false);
    }
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="Campaign Winner Details" size="3xl">
      <div className="flex flex-col h-full max-h-[85vh]">
        <div className="flex-1 overflow-y-auto p-6 space-y-8">
          
          {/* Header Section */}
          <div className="flex items-start justify-between gap-4">
            <div>
              <h3 className="text-2xl font-bold text-surface-900">Winner: Rank #{winner.final_rank}</h3>
              <p className="text-sm font-medium text-surface-500 mt-1 font-mono">ID: {winner.artwork_campaign_winner_id}</p>
            </div>
            <div className="flex flex-col items-end gap-2">
              <span className="shrink-0 inline-flex items-center rounded-full bg-yellow-100 px-3 py-1 text-xs font-bold text-yellow-800 uppercase tracking-wide">
                Confirmed Winner
              </span>
              {artwork ? (
                <span className="shrink-0 inline-flex items-center rounded-full bg-green-100 px-3 py-1 text-xs font-bold text-green-800 uppercase tracking-wide">
                  Promoted Artwork
                </span>
              ) : (
                <span className="shrink-0 inline-flex items-center rounded-full bg-surface-100 px-3 py-1 text-xs font-bold text-surface-600 uppercase tracking-wide">
                  Not Promoted
                </span>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            
            {/* Left Column: Image & Basic Info */}
            <div className="space-y-6">
              <div className="overflow-hidden rounded-xl border border-surface-200 bg-surface-50 aspect-square flex items-center justify-center">
                {submission?.artwork_file_url ? (
                  <img src={submission.artwork_file_url} alt="" className="h-full w-full object-cover" />
                ) : (
                  <span className="text-sm text-surface-400">No Image Available</span>
                )}
              </div>

              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Artwork Info</h4>
                <div className="mt-3 space-y-4">
                  <div>
                    <p className="text-sm text-surface-500">Title</p>
                    <p className="font-semibold text-surface-900">{submission?.artwork_title || 'Unknown Title'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-surface-500">Artist</p>
                    <p className="font-medium text-surface-900">{submission?.profiles?.display_name || 'Unknown Artist'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-surface-500">Description</p>
                    <p className="text-sm text-surface-700 mt-1">{submission?.artwork_description || 'No description provided.'}</p>
                  </div>
                  <div>
                    <p className="text-sm text-surface-500">Cultural Inspiration</p>
                    <p className="text-sm text-surface-700 mt-1">{submission?.cultural_inspiration || 'No cultural inspiration provided.'}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column: Campaign & Voting Info */}
            <div className="space-y-8">
              
              {/* Campaign Context */}
              <div className="rounded-lg border border-surface-200 bg-surface-50 p-5">
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-4">Campaign Context</h4>
                <div className="space-y-4">
                  <div>
                    <p className="text-sm text-surface-500">Campaign</p>
                    <p className="font-medium text-surface-900">{campaign?.campaign_title}</p>
                    <p className="text-xs text-surface-500 mt-1 line-clamp-2">{campaign?.description}</p>
                  </div>

                </div>
              </div>

              {/* Voting Results */}
              <div className="rounded-lg border border-surface-200 bg-white p-5 shadow-sm">
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-4">Voting Results</h4>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-surface-500">Final Vote Count</p>
                    <p className="text-2xl font-bold text-primary-600 mt-1">{winner.final_vote_count}</p>
                  </div>
                  <div>
                    <p className="text-sm text-surface-500">Result Finalised</p>
                    <p className="text-sm font-medium text-surface-900 mt-1">{announcedDate}</p>
                  </div>
                  <div className="col-span-2">
                    <p className="text-sm text-surface-500">Voting Session Context</p>
                    <p className="text-sm font-medium text-surface-900 mt-1 uppercase">
                      {session?.session_type ? session.session_type.replace('_', ' ') : 'Standard'}
                      <span className="ml-2 font-mono text-xs text-surface-500 normal-case">({session?.artwork_voting_session_id})</span>
                    </p>
                  </div>
                </div>
              </div>

              {/* Artwork Promotion Status */}
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-3">Artwork Catalogue Status</h4>
                {artwork ? (
                  <div className="rounded-lg border border-green-200 bg-green-50 p-4">
                    <div className="flex items-center gap-3">
                      <div className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100 text-green-600">
                        <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"/></svg>
                      </div>
                      <div>
                        <p className="text-sm font-bold text-green-900">Successfully Promoted</p>
                        <p className="text-xs font-medium text-green-700 mt-0.5">Artwork ID: <span className="font-mono">{artwork.artwork_id}</span></p>
                        <p className="text-xs text-green-600 mt-0.5">Status: {artwork.status}</p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="rounded-lg border border-surface-200 bg-white p-4 shadow-sm flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-surface-900">Pending Promotion</p>
                      <p className="text-xs text-surface-500 mt-0.5">This winner has not yet been added to the catalogue.</p>
                    </div>
                    <button
                      onClick={() => onPromote(winner, submission)}
                      className="shrink-0 rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
                    >
                      Promote to Artwork
                    </button>
                  </div>
                )}
              </div>

            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="shrink-0 flex flex-col gap-2 border-t border-surface-200 p-6 bg-surface-50">
          {pdfError && (
            <div className="rounded-md bg-red-50 p-3 text-sm text-red-600 border border-red-200">
              {pdfError}
            </div>
          )}
          <div className="flex items-center justify-end gap-3">
            <button
              onClick={handleDownloadPDF}
              disabled={isGeneratingPDF}
              className="inline-flex items-center rounded-lg bg-white px-4 py-2 text-sm font-medium text-surface-700 shadow-sm border border-surface-300 hover:bg-surface-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isGeneratingPDF ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-surface-500" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Generating PDF...
                </>
              ) : (
                <>
                  <svg className="-ml-1 mr-2 h-4 w-4 text-surface-500" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/></svg>
                  Download Handover PDF
                </>
              )}
            </button>
            <button
              onClick={onClose}
              className="rounded-lg px-6 py-2 text-sm font-medium text-surface-700 hover:bg-surface-200"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </Modal>
  );
}

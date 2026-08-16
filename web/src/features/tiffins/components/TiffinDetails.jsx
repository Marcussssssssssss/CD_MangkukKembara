import { useState, useEffect, useRef } from 'react';
import Modal from '../../../components/Modal';
import QRCode from 'qrcode';

export default function TiffinDetails({ tiffin, isOpen, onClose, onEdit, onGenerateQr, referenceData }) {
  const [qrImageUrl, setQrImageUrl] = useState(null);
  const [isGeneratingQr, setIsGeneratingQr] = useState(false);
  const [qrError, setQrError] = useState(null);
  const canvasRef = useRef(null);

  const qrCode = tiffin?.tiffin_qr_codes?.length > 0 ? tiffin.tiffin_qr_codes[0] : null;

  useEffect(() => {
    if (qrCode?.code_value) {
      setIsGeneratingQr(true);
      setQrError(null);
      QRCode.toDataURL(qrCode.code_value, {
        width: 200,
        margin: 2,
        color: { dark: '#1a1a2e', light: '#ffffff' },
        errorCorrectionLevel: 'H',
      })
      .then(url => {
        setQrImageUrl(url);
        setIsGeneratingQr(false);
      })
      .catch(() => {
        setQrError('Failed to render QR code image.');
        setIsGeneratingQr(false);
      });
    } else {
      setQrImageUrl(null);
    }
  }, [qrCode]);

  if (!tiffin || !referenceData) return null;

  const foodObj = referenceData.foods?.find(f => f.heritage_food_id === tiffin.heritage_food_id);
  const artObj = referenceData.artworks?.find(a => a.artwork_id === tiffin.artwork_id);
  const stateObj = referenceData.states?.find(s => s.state_id === tiffin.state_id);

  const foodName = foodObj ? foodObj.food_name : 'Unknown Food';
  const artistName = artObj && artObj.profiles ? artObj.profiles.display_name : 'Unknown Artist';
  const stateName = stateObj ? stateObj.state_name : 'Unknown State';

  const statusColors = {
    active: 'bg-green-100 text-green-700',
    draft: 'bg-yellow-100 text-yellow-700',
    inactive: 'bg-red-100 text-red-700',
  };

  const statusDisplay = tiffin.status.charAt(0).toUpperCase() + tiffin.status.slice(1);
  const story = tiffin.heritage_stories && tiffin.heritage_stories.length > 0 ? tiffin.heritage_stories[0] : null;

  const handleDownloadQr = () => {
    if (!qrImageUrl || !qrCode) return;
    const link = document.createElement('a');
    link.download = `QR_${qrCode.code_value}.png`;
    link.href = qrImageUrl;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="Tiffin Details" size="lg">
      <div className="flex flex-col md:flex-row">
        {/* Left Side: Image */}
        <div className="w-full md:w-1/3 shrink-0">
          <div 
            className="aspect-square w-full bg-surface-100 md:aspect-[3/4] md:rounded-bl-xl"
          >
            {tiffin.cover_image_url ? (
              <img 
                src={tiffin.cover_image_url} 
                alt={tiffin.edition_name}
                className="h-full w-full object-cover md:rounded-bl-xl"
              />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-primary-100 to-surface-200 md:rounded-bl-xl">
                <span className="text-sm font-medium text-surface-400">No Image</span>
              </div>
            )}
          </div>
        </div>

        {/* Right Side: Details */}
        <div className="flex-1 overflow-y-auto p-6 md:max-h-[70vh]">
          <div className="flex items-start justify-between gap-4">
            <h3 className="text-2xl font-bold text-surface-900">{tiffin.edition_name}</h3>
            <span className={`shrink-0 inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[tiffin.status] || 'bg-surface-100 text-surface-700'}`}>
              {statusDisplay}
            </span>
          </div>

          <div className="mt-6 space-y-6">
            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Description</h4>
              <p className="mt-1 text-sm text-surface-700">{tiffin.description || 'No description provided.'}</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Heritage Food</h4>
                <p className="mt-1 text-sm text-surface-900">{foodName}</p>
              </div>
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">State</h4>
                <p className="mt-1 text-sm text-surface-900">{stateName}</p>
              </div>
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Artist</h4>
                <p className="mt-1 text-sm text-surface-900">{artistName}</p>
              </div>
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Release Year</h4>
                <p className="mt-1 text-sm text-surface-900">{tiffin.release_year || 'N/A'}</p>
              </div>
            </div>

            <div>
              <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400">Cultural Significance</h4>
              <p className="mt-1 text-sm text-surface-700">{tiffin.cultural_significance || 'N/A'}</p>
            </div>

            {story && (
              <div className="rounded-lg border border-surface-200 bg-surface-50 p-4">
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-2">
                  Heritage Story
                </h4>
                <p className="text-sm font-semibold text-surface-900 mb-1">{story.title}</p>
                <p className="text-sm text-surface-700">{story.story_body}</p>
              </div>
            )}

            {qrCode ? (
              <div>
                <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-3">QR Code Info</h4>
                <div className="rounded-lg border border-surface-200 bg-surface-50 p-4">
                  <div className="flex flex-col sm:flex-row gap-4 items-center sm:items-start">
                    <div className="shrink-0 bg-white p-2 rounded-lg border border-surface-200 shadow-sm">
                      {isGeneratingQr ? (
                        <div className="flex h-[150px] w-[150px] items-center justify-center">
                          <div className="h-6 w-6 animate-spin rounded-full border-2 border-surface-300 border-t-primary-600" />
                        </div>
                      ) : qrError ? (
                        <div className="flex h-[150px] w-[150px] items-center justify-center">
                          <p className="text-xs text-red-600">{qrError}</p>
                        </div>
                      ) : qrImageUrl ? (
                        <img
                          src={qrImageUrl}
                          alt={`QR code for ${qrCode.code_value}`}
                          className="h-[150px] w-[150px]"
                          ref={canvasRef}
                        />
                      ) : (
                        <div className="flex h-[150px] w-[150px] items-center justify-center bg-surface-100">
                          <span className="text-xs text-surface-400">No Image</span>
                        </div>
                      )}
                    </div>
                    <div className="flex-1 w-full flex flex-col justify-between">
                      <div>
                        <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider mb-1">Code Value</p>
                        <p className="text-sm font-mono font-semibold text-surface-900 break-all">{qrCode.code_value}</p>
                        <p className="text-[11px] text-surface-500 mt-2">
                          ID: {qrCode.tiffin_qr_code_id}
                        </p>
                        <div className="mt-1">
                          <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold ${qrCode.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                            {qrCode.is_active ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                      </div>
                      
                      <div className="mt-4 pt-4 border-t border-surface-200">
                        <button
                          onClick={handleDownloadQr}
                          disabled={!qrImageUrl || isGeneratingQr}
                          className="flex w-full items-center justify-center gap-2 rounded-lg bg-white px-3 py-2 text-sm font-medium text-surface-700 shadow-sm border border-surface-300 hover:bg-surface-50 disabled:opacity-50"
                        >
                          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
                          </svg>
                          Download QR Code
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              <div className="rounded-lg border border-surface-200 border-dashed bg-surface-50 p-4 flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-medium uppercase tracking-wider text-surface-400 mb-1">QR Code</h4>
                  <p className="text-sm text-surface-500">No QR code has been generated for this tiffin yet.</p>
                </div>
                <button
                  onClick={() => onGenerateQr(tiffin)}
                  className="shrink-0 inline-flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0 1 3.75 9.375v-4.5ZM3.75 14.625c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5a1.125 1.125 0 0 1-1.125-1.125v-4.5ZM13.5 4.875c0-.621.504-1.125 1.125-1.125h4.5c.621 0 1.125.504 1.125 1.125v4.5c0 .621-.504 1.125-1.125 1.125h-4.5A1.125 1.125 0 0 1 13.5 9.375v-4.5Z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 6.75h.75v.75h-.75v-.75ZM6.75 16.5h.75v.75h-.75v-.75ZM16.5 6.75h.75v.75h-.75v-.75ZM13.5 13.5h.75v.75h-.75v-.75ZM13.5 19.5h.75v.75h-.75v-.75ZM19.5 13.5h.75v.75h-.75v-.75ZM19.5 19.5h.75v.75h-.75v-.75ZM16.5 16.5h.75v.75h-.75v-.75Z" />
                  </svg>
                  Generate QR
                </button>
              </div>
            )}
          </div>

          <div className="mt-8 flex justify-end gap-3 border-t border-surface-100 pt-4">
            <button
              onClick={onClose}
              className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100"
            >
              Close
            </button>
            <button
              onClick={() => onEdit(tiffin)}
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

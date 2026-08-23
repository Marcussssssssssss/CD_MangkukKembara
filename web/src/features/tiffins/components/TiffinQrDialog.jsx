import { useState, useEffect } from 'react';
import Modal from '../../../components/Modal';
import QRCode from 'qrcode';

export default function TiffinQrDialog({ qrData, tiffin, isOpen, onClose }) {
  if (!qrData) return null;
  return (
    <TiffinQrDialogContent
      key={`${qrData.code_value}-${isOpen}`}
      qrData={qrData}
      tiffin={tiffin}
      isOpen={isOpen}
      onClose={onClose}
    />
  );
}

function TiffinQrDialogContent({ qrData, tiffin, isOpen, onClose }) {
  const [qrImageUrl, setQrImageUrl] = useState(null);
  const [isGenerating, setIsGenerating] = useState(true);
  const [qrError, setQrError] = useState(null);

  useEffect(() => {
    let isMounted = true;
    QRCode.toDataURL(qrData.code_value, {
      width: 300,
      margin: 2,
      color: { dark: '#1a1a2e', light: '#ffffff' },
      errorCorrectionLevel: 'H',
    })
      .then((url) => {
        if (!isMounted) return;
        setQrImageUrl(url);
        setIsGenerating(false);
      })
      .catch(() => {
        if (!isMounted) return;
        setQrError('Failed to render QR code image.');
        setIsGenerating(false);
      });
    return () => { isMounted = false; };
  }, [qrData.code_value]);

  const handleDownload = () => {
    if (!qrImageUrl || !qrData) return;

    const link = document.createElement('a');
    link.download = `QR_${qrData.code_value}.png`;
    link.href = qrImageUrl;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <Modal open={isOpen} onClose={onClose} title="QR Code Generated" size="sm">
      <div className="p-6 flex flex-col items-center text-center">

        {/* Success header */}
        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-green-100 mb-4">
          <svg className="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
        </div>

        <h3 className="text-lg font-bold text-surface-900 mb-1">
          Tiffin Created Successfully
        </h3>
        <p className="text-sm text-surface-500 mb-2">
          A QR code has been generated for this Heritage Tiffin.
        </p>

        {tiffin && (
          <div className="w-full bg-surface-50 border border-surface-200 rounded-lg p-3 mb-6">
            <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider mb-1">Edition</p>
            <p className="text-sm font-semibold text-surface-900">{tiffin.edition_name}</p>
          </div>
        )}

        {/* QR code preview */}
        <div className="rounded-xl border border-surface-200 bg-white p-4 shadow-sm mb-4">
          {isGenerating ? (
            <div className="flex h-[200px] w-[200px] items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-surface-300 border-t-primary-600" />
            </div>
          ) : qrError ? (
            <div className="flex h-[200px] w-[200px] items-center justify-center">
              <p className="text-sm text-red-600">{qrError}</p>
            </div>
          ) : qrImageUrl ? (
            <img
              src={qrImageUrl}
              alt={`QR code for ${qrData.code_value}`}
              className="h-[200px] w-[200px]"
            />
          ) : null}
        </div>

        {/* QR code value */}
        <div className="rounded-lg bg-surface-50 border border-surface-200 px-4 py-2 mb-6 w-full">
          <p className="text-[11px] font-bold text-surface-400 uppercase tracking-wider mb-1">Code Value</p>
          <p className="text-sm font-mono font-semibold text-surface-900">{qrData.code_value}</p>
          <p className="text-[11px] text-surface-500 mt-1">
            ID: {qrData.tiffin_qr_code_id} · {qrData.is_active ? 'Active' : 'Inactive'}
          </p>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 w-full">
          <button
            onClick={onClose}
            className="flex-1 rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-100 border border-surface-200"
          >
            Close
          </button>
          <button
            onClick={handleDownload}
            disabled={!qrImageUrl || isGenerating}
            className="flex-1 flex items-center justify-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
            </svg>
            Download QR
          </button>
        </div>
      </div>
    </Modal>
  );
}

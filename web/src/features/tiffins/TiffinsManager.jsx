import { useState, useMemo, useEffect } from 'react';
import TiffinDashboard from './components/TiffinDashboard';
import TiffinDetails from './components/TiffinDetails';
import TiffinForm from './components/TiffinForm';
import TiffinDeactivateDialog from './components/TiffinDeactivateDialog';
import TiffinQrDialog from './components/TiffinQrDialog';
import { 
  fetchTiffins, 
  fetchReferenceData, 
  createTiffin, 
  updateTiffin, 
  deactivateTiffin,
  generateTiffinQrCode 
} from './services/tiffinService';

export default function TiffinsManager() {
  // --- Data State ---
  const [tiffins, setTiffins] = useState([]);
  const [referenceData, setReferenceData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const [searchQuery, setSearchQuery] = useState('');
  
  // Modals state
  const [viewingTiffin, setViewingTiffin] = useState(null);
  const [editingTiffin, setEditingTiffin] = useState(null);
  const [isCreating, setIsCreating] = useState(false);
  const [deactivatingTiffin, setDeactivatingTiffin] = useState(null);
  const [qrResult, setQrResult] = useState(null);

  // Notifications
  const [feedbackMessage, setFeedbackMessage] = useState(null);
  const [feedbackType, setFeedbackType] = useState('success');

  const showFeedback = (msg, type = 'success') => {
    setFeedbackMessage(msg);
    setFeedbackType(type);
    setTimeout(() => setFeedbackMessage(null), 5000);
  };

  // --- Data Fetching ---
  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        const [tiffinData, refData] = await Promise.all([
          fetchTiffins(),
          fetchReferenceData()
        ]);
        setTiffins(tiffinData);
        setReferenceData(refData);
      } catch (err) {
        setError(err.message || 'Failed to load tiffin data.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  // --- Derived State ---
  const filteredTiffins = useMemo(() => {
    if (!searchQuery) return tiffins;
    const lowerQuery = searchQuery.toLowerCase();
    return tiffins.filter(
      (t) =>
        t.edition_name.toLowerCase().includes(lowerQuery) ||
        (t.description && t.description.toLowerCase().includes(lowerQuery))
    );
  }, [tiffins, searchQuery]);

  // --- Handlers ---
  const handleCreate = () => setIsCreating(true);
  
  const handleView = (tiffin) => setViewingTiffin(tiffin);
  
  const handleEdit = (tiffin) => {
    setViewingTiffin(null);
    setEditingTiffin(tiffin);
  };
  
  const handleDeactivate = (tiffin) => setDeactivatingTiffin(tiffin);

  const handleCloseModals = () => {
    setIsCreating(false);
    setEditingTiffin(null);
    setViewingTiffin(null);
    setDeactivatingTiffin(null);
  };

  const handleCloseQrDialog = () => setQrResult(null);

  // --- Save Operations ---
  const handleSaveTiffin = async (tiffinData, files) => {
    try {
      if (editingTiffin) {
        const updated = await updateTiffin(tiffinData.heritage_tiffin_id, tiffinData, files);
        setTiffins((prev) => 
          prev.map((t) => (t.heritage_tiffin_id === updated.heritage_tiffin_id ? updated : t))
        );
        showFeedback('Tiffin edition updated successfully.');
        handleCloseModals();
      } else {
        const created = await createTiffin(tiffinData, files);
        setTiffins((prev) => [created, ...prev]);
        handleCloseModals();

        // Attempt QR code generation after successful tiffin creation
        try {
          const qr = await generateTiffinQrCode(created.heritage_tiffin_id);
          // Update the tiffin in local state with its new QR
          setTiffins((prev) =>
            prev.map((t) =>
              t.heritage_tiffin_id === created.heritage_tiffin_id
                ? { ...t, tiffin_qr_codes: [{ code_value: qr.code_value, is_active: qr.is_active }] }
                : t
            )
          );
          setQrResult({ qrData: qr, tiffin: created });
        } catch (qrErr) {
          showFeedback(
            `Tiffin created but QR generation failed: ${qrErr.message || 'Unknown error'}. You can retry from Tiffin Details.`,
            'error'
          );
        }
      }
    } catch (err) {
      throw err;
    }
  };

  const handleGenerateQr = async (tiffin) => {
    try {
      const qr = await generateTiffinQrCode(tiffin.heritage_tiffin_id);
      setTiffins((prev) =>
        prev.map((t) =>
          t.heritage_tiffin_id === tiffin.heritage_tiffin_id
            ? { ...t, tiffin_qr_codes: [{ code_value: qr.code_value, is_active: qr.is_active }] }
            : t
        )
      );
      setViewingTiffin(null);
      setQrResult({ qrData: qr, tiffin });
    } catch (err) {
      showFeedback(err.message || 'Failed to generate QR code.', 'error');
    }
  };

  const handleConfirmDeactivate = async (id) => {
    try {
      await deactivateTiffin(id);
      setTiffins((prev) =>
        prev.map((t) => (t.heritage_tiffin_id === id ? { ...t, status: 'inactive' } : t))
      );
      showFeedback('Tiffin edition deactivated.');
      handleCloseModals();
    } catch (err) {
      showFeedback(err.message || 'Failed to deactivate tiffin.', 'error');
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-surface-300 border-t-primary-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-500/20 bg-red-50 p-4 text-sm text-red-600 m-4">
        {error}
      </div>
    );
  }

  return (
    <div className="relative">
      {feedbackMessage && (
        <div className={`fixed bottom-4 right-4 z-50 rounded-lg px-4 py-2 text-sm text-white shadow-lg animate-in fade-in slide-in-from-bottom-2 ${feedbackType === 'error' ? 'bg-red-600' : 'bg-surface-900'}`}>
          {feedbackMessage}
        </div>
      )}

      <TiffinDashboard
        tiffins={filteredTiffins}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        onCreate={handleCreate}
        onView={handleView}
        onEdit={handleEdit}
        onDeactivate={handleDeactivate}
        referenceData={referenceData}
      />

      <TiffinDetails
        tiffin={viewingTiffin}
        isOpen={!!viewingTiffin}
        onClose={handleCloseModals}
        onEdit={handleEdit}
        onGenerateQr={handleGenerateQr}
        referenceData={referenceData}
      />

      <TiffinForm
        tiffin={editingTiffin}
        isOpen={isCreating || !!editingTiffin}
        onClose={handleCloseModals}
        onSave={handleSaveTiffin}
        referenceData={referenceData}
      />

      <TiffinDeactivateDialog
        tiffin={deactivatingTiffin}
        isOpen={!!deactivatingTiffin}
        onClose={handleCloseModals}
        onConfirm={handleConfirmDeactivate}
      />

      <TiffinQrDialog
        qrData={qrResult?.qrData}
        tiffin={qrResult?.tiffin}
        isOpen={!!qrResult}
        onClose={handleCloseQrDialog}
      />
    </div>
  );
}

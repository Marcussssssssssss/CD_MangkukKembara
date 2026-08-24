import { useState, useMemo, useEffect } from 'react';
import TiffinDashboard from './components/TiffinDashboard';
import TiffinDetails from './components/TiffinDetails';
import TiffinForm from './components/TiffinForm';
import TiffinDeactivateDialog from './components/TiffinDeactivateDialog';
import TiffinQrDialog from './components/TiffinQrDialog';
import NotificationCenter from '../../components/NotificationCenter';
import { useNotifier } from '../../hooks/useNotifier';
import { 
  fetchTiffins, 
  fetchReferenceData, 
  createTiffin, 
  createHeritageFood,
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

  const {
    notifications,
    success: notifySuccess,
    failure: notifyFailure,
    dismiss: dismissNotification,
  } = useNotifier();

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
    const artworkById = new Map(
      (referenceData?.artworks || []).map(artwork => [artwork.artwork_id, artwork])
    );
    const stateById = new Map(
      (referenceData?.states || []).map(state => [state.state_id, state])
    );
    const foodById = new Map(
      (referenceData?.foods || []).map(food => [food.heritage_food_id, food])
    );

    return tiffins.filter((tiffin) => {
      const artwork = artworkById.get(tiffin.artwork_id);
      const searchableText = [
        tiffin.edition_name,
        artwork?.title,
        artwork?.profiles?.display_name,
        stateById.get(tiffin.state_id)?.state_name,
        foodById.get(tiffin.heritage_food_id)?.food_name,
      ].filter(Boolean).join(' ').toLowerCase();
      return searchableText.includes(lowerQuery);
    });
  }, [tiffins, searchQuery, referenceData]);

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

  const syncArtworkAssignment = (tiffinId, artworkId) => {
    setReferenceData((prev) => {
      if (!prev) return prev;
      return {
        ...prev,
        artworks: prev.artworks.map((artwork) => ({
          ...artwork,
          assigned_tiffin_id: artwork.artwork_id === artworkId
            ? tiffinId
            : artwork.assigned_tiffin_id === tiffinId
              ? null
              : artwork.assigned_tiffin_id,
        })),
      };
    });
  };

  // --- Save Operations ---
  const handleSaveTiffin = async (tiffinData, files) => {
    const isEditing = Boolean(editingTiffin);

    try {
      if (isEditing) {
        const updated = await updateTiffin(tiffinData.heritage_tiffin_id, tiffinData, files);
        setTiffins((prev) =>
          prev.map((t) => (t.heritage_tiffin_id === updated.heritage_tiffin_id ? updated : t))
        );
        syncArtworkAssignment(updated.heritage_tiffin_id, updated.artwork_id);
        notifySuccess('Tiffin edition updated successfully.');
        handleCloseModals();
      } else {
        const created = await createTiffin(tiffinData, files);
        setTiffins((prev) => [created, ...prev]);
        syncArtworkAssignment(created.heritage_tiffin_id, created.artwork_id);
        notifySuccess('Tiffin edition created successfully.');
        handleCloseModals();

        // Attempt QR code generation after successful tiffin creation.
        try {
          const qr = await generateTiffinQrCode(created.heritage_tiffin_id);
          setTiffins((prev) =>
            prev.map((t) =>
              t.heritage_tiffin_id === created.heritage_tiffin_id
                ? { ...t, tiffin_qr_codes: [{ tiffin_qr_code_id: qr.tiffin_qr_code_id, code_value: qr.code_value, is_active: qr.is_active }] }
                : t
            )
          );
          notifySuccess('QR code generated successfully.');
          setQrResult({ qrData: qr, tiffin: created });
        } catch (qrErr) {
          notifyFailure(
            `The Tiffin was created, but its QR code could not be generated. ${qrErr.message || 'Please retry from Tiffin Details.'}`
          );
        }
      }
    } catch (err) {
      notifyFailure(
        err.message || `The Tiffin edition could not be ${isEditing ? 'updated' : 'created'}.`
      );
      throw err;
    }
  };

  const handleCreateHeritageFood = async (foodData, imageFile) => {
    try {
      const createdFood = await createHeritageFood(foodData, imageFile);
      setReferenceData(prev => ({
        ...prev,
        foods: [...(prev?.foods || []), createdFood]
          .sort((a, b) => a.food_name.localeCompare(b.food_name)),
      }));
      notifySuccess(`${createdFood.food_name} was added to Heritage Foods.`);
      return createdFood;
    } catch (err) {
      notifyFailure(err.message || 'The Heritage Food could not be created.');
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
      notifySuccess('QR code generated successfully.');
      setQrResult({ qrData: qr, tiffin });
    } catch (err) {
      notifyFailure(err.message || 'The QR code could not be generated.');
    }
  };

  const handleConfirmDeactivate = async (id) => {
    try {
      await deactivateTiffin(id);
      setTiffins((prev) =>
        prev.map((t) => (t.heritage_tiffin_id === id ? { ...t, status: 'inactive' } : t))
      );
      notifySuccess('Tiffin edition deactivated successfully.');
      handleCloseModals();
    } catch (err) {
      notifyFailure(err.message || 'The Tiffin edition could not be deactivated.');
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
      <NotificationCenter notifications={notifications} onDismiss={dismissNotification} />

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
        onCreateHeritageFood={handleCreateHeritageFood}
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

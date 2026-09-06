import { useState, useMemo, useEffect } from 'react';
import VendorDashboard from './components/VendorDashboard';
import VendorDetails from './components/VendorDetails';
import VendorForm from './components/VendorForm';
import VendorDeactivateDialog from './components/VendorDeactivateDialog';
import NotificationCenter from '../../components/NotificationCenter';
import { useNotifier } from '../../hooks/useNotifier';
import { createHeritageFood } from '../tiffins/services/tiffinService';
import { 
  fetchVendors, 
  fetchReferenceData, 
  createVendor, 
  updateVendor, 
  deactivateVendor 
} from './services/vendorService';

export default function VendorsManager() {
  // --- Data State ---
  const [vendors, setVendors] = useState([]);
  const [referenceData, setReferenceData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const [searchQuery, setSearchQuery] = useState('');
  
  // Modals state
  const [viewingVendor, setViewingVendor] = useState(null);
  const [editingVendor, setEditingVendor] = useState(null);
  const [isCreating, setIsCreating] = useState(false);
  const [deactivatingVendor, setDeactivatingVendor] = useState(null);
  const [isDeactivating, setIsDeactivating] = useState(false);

  const {
    notifications,
    success: notifySuccess,
    failure: notifyFailure,
    dismiss: dismissNotification,
  } = useNotifier();

  useEffect(() => {
    let isMounted = true;
    Promise.all([fetchVendors(), fetchReferenceData()])
      .then(([vendorData, refData]) => {
        if (!isMounted) return;
        setVendors(vendorData);
        setReferenceData(refData);
      })
      .catch((err) => {
        if (isMounted) setError(err.message || 'Failed to load vendor data.');
      })
      .finally(() => {
        if (isMounted) setIsLoading(false);
      });
    return () => { isMounted = false; };
  }, []);

  const reloadData = async () => {
    const [vendorData, refData] = await Promise.all([fetchVendors(), fetchReferenceData()]);
    setVendors(vendorData);
    setReferenceData(refData);
  };

  // --- Derived State ---
  const filteredVendors = useMemo(() => {
    if (!searchQuery) return vendors;
    const lowerQuery = searchQuery.toLowerCase();
    return vendors.filter(
      (v) =>
        v.vendor_name.toLowerCase().includes(lowerQuery) ||
        v.business_type.toLowerCase().includes(lowerQuery)
    );
  }, [vendors, searchQuery]);

  // --- Handlers ---
  const handleCreate = () => setIsCreating(true);
  
  const handleView = (vendor) => setViewingVendor(vendor);
  
  const handleEdit = (vendor) => {
    setViewingVendor(null);
    setEditingVendor(vendor);
  };
  
  const handleDeactivate = (vendor) => setDeactivatingVendor(vendor);

  const handleCloseModals = () => {
    setIsCreating(false);
    setEditingVendor(null);
    setViewingVendor(null);
    setDeactivatingVendor(null);
  };

  // --- Save Operations ---
  const handleSaveVendor = async (vendorData) => {
    const isEditing = Boolean(editingVendor);

    try {
      if (isEditing) {
        await updateVendor(vendorData.vendor_id, vendorData);
      } else {
        await createVendor(vendorData);
      }
    } catch (err) {
      notifyFailure(err.message || `The vendor could not be ${isEditing ? 'updated' : 'created'}.`);
      throw err;
    }

    notifySuccess(`Vendor ${isEditing ? 'updated' : 'created'} successfully.`);
    handleCloseModals();

    try {
      await reloadData();
    } catch (err) {
      notifyFailure(
        err.message
          ? `The vendor was saved, but the latest list could not be loaded. ${err.message}`
          : 'The vendor was saved, but the latest list could not be loaded. Please refresh the page.'
      );
    }
  };

  const handleCreateHeritageFood = async (foodData, imageFile) => {
    try {
      const createdFood = await createHeritageFood(foodData, imageFile);
      setReferenceData(prev => ({
        ...prev,
        foods: [...(prev?.foods || []), createdFood]
          .sort((left, right) => left.food_name.localeCompare(right.food_name)),
      }));
      notifySuccess(`${createdFood.food_name} was added to Heritage Foods.`);
      return createdFood;
    } catch (err) {
      notifyFailure(err.message || 'The Heritage Food could not be created.');
      throw err;
    }
  };

  const handleConfirmDeactivate = async (id) => {
    if (isDeactivating) return;
    setIsDeactivating(true);
    try {
      await deactivateVendor(id);
      setVendors((prev) =>
        prev.map((v) => (v.vendor_id === id ? { ...v, participation_status: 'inactive' } : v))
      );
      notifySuccess('Vendor deactivated successfully.');
      handleCloseModals();
    } catch (err) {
      notifyFailure(err.message || 'The vendor could not be deactivated.');
    } finally {
      setIsDeactivating(false);
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

      <VendorDashboard
        vendors={filteredVendors}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        onCreate={handleCreate}
        onView={handleView}
        onEdit={handleEdit}
        onDeactivate={handleDeactivate}
      />

      <VendorDetails
        vendor={viewingVendor}
        isOpen={!!viewingVendor}
        onClose={handleCloseModals}
        onEdit={handleEdit}
      />

      <VendorForm
        vendor={editingVendor}
        isOpen={isCreating || !!editingVendor}
        onClose={handleCloseModals}
        onSave={handleSaveVendor}
        onCreateHeritageFood={handleCreateHeritageFood}
        referenceData={referenceData}
      />

      <VendorDeactivateDialog
        vendor={deactivatingVendor}
        isOpen={!!deactivatingVendor}
        onClose={isDeactivating ? undefined : handleCloseModals}
        onConfirm={handleConfirmDeactivate}
        isProcessing={isDeactivating}
      />
    </div>
  );
}

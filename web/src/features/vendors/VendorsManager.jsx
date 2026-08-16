import { useState, useMemo, useEffect } from 'react';
import VendorDashboard from './components/VendorDashboard';
import VendorDetails from './components/VendorDetails';
import VendorForm from './components/VendorForm';
import VendorDeactivateDialog from './components/VendorDeactivateDialog';
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

  // Notifications
  const [feedbackMessage, setFeedbackMessage] = useState(null);
  const [feedbackType, setFeedbackType] = useState('success');

  const showFeedback = (msg, type = 'success') => {
    setFeedbackMessage(msg);
    setFeedbackType(type);
    setTimeout(() => setFeedbackMessage(null), 5000);
  };

  // --- Data Fetching ---
  const loadData = async () => {
    try {
      setIsLoading(true);
      const [vendorData, refData] = await Promise.all([
        fetchVendors(),
        fetchReferenceData()
      ]);
      setVendors(vendorData);
      setReferenceData(refData);
    } catch (err) {
      setError(err.message || 'Failed to load vendor data.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

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
    try {
      if (editingVendor) {
        await updateVendor(vendorData.vendor_id, vendorData);
        showFeedback('Vendor updated successfully.');
      } else {
        await createVendor(vendorData);
        showFeedback('New vendor created.');
      }
      handleCloseModals();
      await loadData(); // Reload all to get generated joined data nicely
    } catch (err) {
      // Re-throw to the form so it displays the error
      throw err;
    }
  };

  const handleConfirmDeactivate = async (id) => {
    try {
      await deactivateVendor(id);
      setVendors((prev) =>
        prev.map((v) => (v.vendor_id === id ? { ...v, participation_status: 'inactive' } : v))
      );
      showFeedback('Vendor deactivated.');
      handleCloseModals();
    } catch (err) {
      showFeedback(err.message || 'Failed to deactivate vendor.', 'error');
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
        referenceData={referenceData}
      />

      <VendorDeactivateDialog
        vendor={deactivatingVendor}
        isOpen={!!deactivatingVendor}
        onClose={handleCloseModals}
        onConfirm={handleConfirmDeactivate}
      />
    </div>
  );
}

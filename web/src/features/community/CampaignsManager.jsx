import { useState, useEffect, useMemo } from 'react';
import CampaignDashboard from './components/CampaignDashboard';
import CampaignForm from './components/CampaignForm';
import CampaignDetails from './components/CampaignDetails';
import WinnerDetails from './components/WinnerDetails';
import CampaignDeactivateDialog from './components/CampaignDeactivateDialog';
import { fetchCampaigns, fetchReferenceData, createCampaign, updateCampaign, completeCampaign, promoteWinnerToArtwork, deactivateCampaign } from './services/communityService';
import { useAuth } from '../../hooks/useAuth';

export default function CampaignsManager() {
  const { profile } = useAuth();

  // --- Data State ---
  const [campaigns, setCampaigns] = useState([]);
  const [referenceData, setReferenceData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // --- UI State ---
  const [searchQuery, setSearchQuery] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [editingCampaign, setEditingCampaign] = useState(null);
  const [viewingCampaign, setViewingCampaign] = useState(null);
  const [viewingWinner, setViewingWinner] = useState(null);
  const [deactivatingCampaign, setDeactivatingCampaign] = useState(null);

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
        const [campaignData, refData] = await Promise.all([
          fetchCampaigns(),
          fetchReferenceData()
        ]);
        setCampaigns(campaignData);
        setReferenceData(refData);
      } catch (err) {
        setError(err.message || 'Failed to load campaign data.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  // --- Derived State ---
  const filteredCampaigns = useMemo(() => {
    if (!searchQuery) return campaigns;
    const lowerQuery = searchQuery.toLowerCase();
    return campaigns.filter(
      (c) =>
        c.campaign_title.toLowerCase().includes(lowerQuery) ||
        (c.description && c.description.toLowerCase().includes(lowerQuery))
    );
  }, [campaigns, searchQuery]);

  const handleCreate = () => setIsCreating(true);
  
  const handleView = (campaign) => {
    setViewingCampaign(campaign);
  };

  const handleEdit = (campaign) => {
    setViewingCampaign(null);
    setEditingCampaign(campaign);
  };

  const handleViewWinner = (winner) => {
    setViewingWinner(winner);
  };

  const handleCloseModals = () => {
    setIsCreating(false);
    setEditingCampaign(null);
    setViewingCampaign(null);
    setViewingWinner(null);
    setDeactivatingCampaign(null);
  };

  const handleSaveCampaign = async (campaignData, categories) => {
    try {
      if (editingCampaign) {
        const updated = await updateCampaign(editingCampaign.artwork_campaign_id, campaignData, categories);
        setCampaigns((prev) =>
          prev.map((c) => (c.artwork_campaign_id === updated.artwork_campaign_id ? updated : c))
        );
        showFeedback('Campaign updated successfully.');
      } else {
        if (!profile || !profile.profile_id) {
          throw new Error("Unable to determine your profile ID for campaign creation.");
        }
        const created = await createCampaign(campaignData, categories, profile.profile_id);
        setCampaigns((prev) => [created, ...prev]);
        showFeedback('New campaign created successfully.');
      }
      handleCloseModals();
    } catch (err) {
      throw err;
    }
  };

  const handleComplete = async (campaign) => {
    if (window.confirm(`Are you sure you want to mark "${campaign.campaign_title}" as completed? This action will finalize the campaign status.`)) {
      try {
        const completed = await completeCampaign(campaign.artwork_campaign_id);
        setCampaigns((prev) =>
          prev.map((c) => (c.artwork_campaign_id === completed.artwork_campaign_id ? completed : c))
        );
        // If the admin is currently viewing this campaign, update the viewing state so the modal updates too
        if (viewingCampaign && viewingCampaign.artwork_campaign_id === completed.artwork_campaign_id) {
          setViewingCampaign(completed);
        }
        showFeedback('Campaign has been successfully marked as completed.');
      } catch (err) {
        showFeedback(err.message || 'Failed to complete campaign.', 'error');
      }
    }
  };

  const handleDeactivate = (campaign) => {
    setDeactivatingCampaign(campaign);
  };

  const handleConfirmDeactivate = async (campaign) => {
    try {
      const deactivated = await deactivateCampaign(campaign.artwork_campaign_id);
      setCampaigns((prev) =>
        prev.map((c) => (c.artwork_campaign_id === deactivated.artwork_campaign_id ? deactivated : c))
      );
      // If the admin is currently viewing this campaign, update the viewing state
      if (viewingCampaign && viewingCampaign.artwork_campaign_id === deactivated.artwork_campaign_id) {
        setViewingCampaign(deactivated);
      }
      showFeedback('Campaign has been successfully deactivated.');
      handleCloseModals();
    } catch (err) {
      showFeedback(err.message || 'Failed to deactivate campaign.', 'error');
    }
  };

  const handlePromote = async (winner, submission) => {
    if (window.confirm(`Are you sure you want to promote "${submission.artwork_title}" to the official Artwork catalogue? This action cannot be undone.`)) {
      try {
        await promoteWinnerToArtwork(winner.artwork_campaign_winner_id, submission);
        const updatedCampaigns = await fetchCampaigns();
        setCampaigns(updatedCampaigns);
        showFeedback('Artwork promoted successfully!', 'success');
        
        // Refresh viewingCampaign to trigger the useEffect in CampaignDetails to reload winners
        setViewingCampaign({ ...viewingCampaign });
      } catch (err) {
        showFeedback(err.message || 'Failed to promote artwork.', 'error');
      }
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

      <CampaignDashboard
        campaigns={filteredCampaigns}
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        onCreate={handleCreate}
        onView={handleView}
        onEdit={handleEdit}
        onDeactivate={handleDeactivate}
      />

      <CampaignDetails
        campaign={viewingCampaign}
        isOpen={!!viewingCampaign}
        onClose={handleCloseModals}
        onEdit={handleEdit}
        onComplete={handleComplete}
        onPromote={handlePromote}
        onViewWinner={handleViewWinner}
      />

      <WinnerDetails
        winner={viewingWinner}
        isOpen={!!viewingWinner}
        onClose={handleCloseModals}
        onPromote={handlePromote}
      />

      <CampaignForm
        campaign={editingCampaign}
        isOpen={isCreating || !!editingCampaign}
        onClose={handleCloseModals}
        onSave={handleSaveCampaign}
        referenceData={referenceData}
      />

      <CampaignDeactivateDialog
        campaign={deactivatingCampaign}
        isOpen={!!deactivatingCampaign}
        onClose={handleCloseModals}
        onConfirm={handleConfirmDeactivate}
      />
    </div>
  );
}



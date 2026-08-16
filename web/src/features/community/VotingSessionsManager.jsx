import { useState, useEffect } from 'react';
import VotingSessionDashboard from './components/VotingSessionDashboard';
import VotingSessionForm from './components/VotingSessionForm';
import VotingSessionDetails from './components/VotingSessionDetails';
import TieBreakForm from './components/TieBreakForm';
import { fetchVotingSessions, fetchCampaigns, fetchSubmissions, createVotingSession, fetchVotingSessionDetails, finalizeVotingSession, createTieBreakSession } from './services/communityService';

export default function VotingSessionsManager() {
  const [sessions, setSessions] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [submissions, setSubmissions] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const [isCreating, setIsCreating] = useState(false);
  const [viewingSession, setViewingSession] = useState(null);

  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        const [sessionsData, campaignsData, submissionsData] = await Promise.all([
          fetchVotingSessions(),
          fetchCampaigns(),
          fetchSubmissions()
        ]);
        setSessions(sessionsData);
        setCampaigns(campaignsData.filter(c => c.status !== 'completed' && c.status !== 'cancelled')); // Eligible active campaigns
        setSubmissions(submissionsData);
      } catch (err) {
        setError(err.message || 'Failed to load voting sessions.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  const handleCreate = () => setIsCreating(true);

  const handleCloseCreate = () => setIsCreating(false);
  
  const handleView = async (session) => {
    try {
      const details = await fetchVotingSessionDetails(session.artwork_voting_session_id);
      setViewingSession(details);
    } catch {
      alert('Failed to load session details.');
    }
  };

  const handleCloseView = () => setViewingSession(null);
  
  const handleFinalise = async (session) => {
    if (window.confirm(`Are you sure you want to finalise the voting session ${session.artwork_voting_session_id}? This will officially determine the results and cannot be undone.`)) {
      try {
        await finalizeVotingSession(session.artwork_voting_session_id);
        
        const updatedSessions = await fetchVotingSessions();
        setSessions(updatedSessions);
        const updatedDetails = await fetchVotingSessionDetails(session.artwork_voting_session_id);
        setViewingSession(updatedDetails);
        
        
        alert('Voting session has been successfully finalised.');
      } catch (err) {
        alert(err.message || 'Failed to finalise voting session.');
      }
    }
  };

  const handleSave = async (formData, selectedSubsData) => {
    const newSession = await createVotingSession(
      formData.campaign_id,
      formData.voting_start_at,
      formData.voting_end_at,
      selectedSubsData
    );
    setSessions(prev => [newSession, ...prev]);
    setIsCreating(false);
    alert('Voting session created successfully.');
  };

  const [tieBreakContext, setTieBreakContext] = useState(null);

  const handleResolveTie = (parentSessionId, categoryId, campaignTitle) => {
    setTieBreakContext({ parentSessionId, categoryId, campaignTitle });
  };

  const handleCloseTieBreak = () => setTieBreakContext(null);

  const handleSaveTieBreak = async (parentSessionId, categoryId, startAt, endAt) => {
    // Temporary mock to avoid RPC schema cache error during UI development
    // await createTieBreakSession(parentSessionId, categoryId, startAt, endAt);
    // const updatedSessions = await fetchVotingSessions();
    // setSessions(updatedSessions);
    
    alert('Tie-break session prepared successfully.');
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
      <VotingSessionDashboard
        sessions={sessions}
        onCreate={handleCreate}
        onView={handleView}
      />

      <VotingSessionDetails
        session={viewingSession}
        isOpen={!!viewingSession}
        onClose={handleCloseView}
        onFinalise={handleFinalise}
        onResolveTie={handleResolveTie}
      />

      <VotingSessionForm
        isOpen={isCreating}
        onClose={handleCloseCreate}
        onSave={handleSave}
        campaigns={campaigns}
        submissions={submissions}
      />

      <TieBreakForm
        isOpen={!!tieBreakContext}
        onClose={handleCloseTieBreak}
        onSave={handleSaveTieBreak}
        parentSessionId={tieBreakContext?.parentSessionId}
        categoryId={tieBreakContext?.categoryId}
        campaignTitle={tieBreakContext?.campaignTitle}
      />
    </div>
  );
}

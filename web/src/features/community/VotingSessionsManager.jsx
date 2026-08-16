import { useState, useEffect, useRef } from 'react';
import VotingSessionDashboard from './components/VotingSessionDashboard';
import VotingSessionForm from './components/VotingSessionForm';
import VotingSessionDetails from './components/VotingSessionDetails';
import TieBreakForm from './components/TieBreakForm';
import {
  fetchVotingSessions,
  fetchCampaigns,
  fetchSubmissions,
  createVotingSession,
  fetchVotingSessionDetails,
  activateVotingSession,
  closeVotingSession,
  finalizeVotingSession,
  createTieBreakSession
} from './services/communityService';

export default function VotingSessionsManager() {
  const [sessions, setSessions] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [submissions, setSubmissions] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const [isCreating, setIsCreating] = useState(false);
  const [viewingSession, setViewingSession] = useState(null);
  const selectedSessionIdRef = useRef(null);
  const detailRequestIdRef = useRef(0);

  const refreshSessions = async () => {
    const sessionsData = await fetchVotingSessions();
    setSessions(sessionsData);
    return sessionsData;
  };

  const refreshSessionDetails = async (sessionId) => {
    const requestId = ++detailRequestIdRef.current;
    const details = await fetchVotingSessionDetails(sessionId);

    if (
      requestId === detailRequestIdRef.current
      && selectedSessionIdRef.current === sessionId
    ) {
      setViewingSession(details);
    }

    return details;
  };

  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        setError(null);
        const [sessionsData, campaignsData, submissionsData] = await Promise.all([
          fetchVotingSessions(),
          fetchCampaigns(),
          fetchSubmissions()
        ]);
        setSessions(sessionsData);
        setCampaigns(campaignsData.filter(c => c.status === 'active'));
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
    const sessionId = session.artwork_voting_session_id;
    selectedSessionIdRef.current = sessionId;
    setViewingSession(null);

    try {
      await refreshSessionDetails(sessionId);
    } catch (err) {
      alert(err.message || 'Failed to load session details.');
    }
  };

  const handleCloseView = () => {
    selectedSessionIdRef.current = null;
    detailRequestIdRef.current += 1;
    setViewingSession(null);
  };

  const handleActivate = async (session) => {
    const sessionId = session.artwork_voting_session_id;
    if (!window.confirm(`Activate voting session ${sessionId} now?`)) {
      return;
    }

    try {
      await activateVotingSession(sessionId);
      await Promise.all([
        refreshSessions(),
        refreshSessionDetails(sessionId)
      ]);
      alert('Voting session activated successfully.');
    } catch (err) {
      alert(err.message || 'Failed to activate voting session.');
    }
  };
  
  const handleCloseVoting = async (session) => {
    const sessionId = session.artwork_voting_session_id;
    if (!window.confirm(`Close voting session ${sessionId}? Votes can no longer be cast after it is closed.`)) {
      return;
    }

    try {
      await closeVotingSession(sessionId);
      await Promise.all([
        refreshSessions(),
        refreshSessionDetails(sessionId)
      ]);
      alert('Voting session closed successfully.');
    } catch (err) {
      alert(err.message || 'Failed to close voting session.');
    }
  };

  const handleFinalise = async (session) => {
    if (window.confirm(`Are you sure you want to finalise the voting session ${session.artwork_voting_session_id}? This will officially determine the results and cannot be undone.`)) {
      try {
        await finalizeVotingSession(session.artwork_voting_session_id);

        await Promise.all([
          refreshSessions(),
          refreshSessionDetails(session.artwork_voting_session_id)
        ]);

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
    await refreshSessions();
    setIsCreating(false);
    alert('Voting session created successfully.');

    return newSession;
  };

  const [tieBreakContext, setTieBreakContext] = useState(null);

  const handleResolveTie = (parentSessionId, campaignTitle) => {
    setTieBreakContext({ parentSessionId, campaignTitle });
  };

  const handleCloseTieBreak = () => setTieBreakContext(null);

  const handleSaveTieBreak = async (parentSessionId, startAt, endAt) => {
    await createTieBreakSession(parentSessionId, startAt, endAt);
    await Promise.all([
      refreshSessions(),
      refreshSessionDetails(parentSessionId)
    ]);
    setTieBreakContext(null);
    alert('Tie-break session created successfully.');
  };

  const viewingSessionHasChild = viewingSession
    ? sessions.some(
        session => session.parent_voting_session_id === viewingSession.artwork_voting_session_id
      )
    : false;

  const eligibleCampaigns = campaigns.filter(campaign => (
    campaign.status === 'active'
    && !sessions.some(session => (
      session.artwork_campaign_id === campaign.artwork_campaign_id
      && session.session_type === 'standard'
    ))
  ));

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
        onActivate={handleActivate}
        onCloseVoting={handleCloseVoting}
        onFinalise={handleFinalise}
        onResolveTie={handleResolveTie}
        hasTieBreakChild={viewingSessionHasChild}
      />

      <VotingSessionForm
        isOpen={isCreating}
        onClose={handleCloseCreate}
        onSave={handleSave}
        campaigns={eligibleCampaigns}
        submissions={submissions}
      />

      <TieBreakForm
        isOpen={!!tieBreakContext}
        onClose={handleCloseTieBreak}
        onSave={handleSaveTieBreak}
        parentSessionId={tieBreakContext?.parentSessionId}
        campaignTitle={tieBreakContext?.campaignTitle}
      />
    </div>
  );
}

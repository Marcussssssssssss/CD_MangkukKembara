import { useState, useMemo, useEffect } from 'react';
import SubmissionDashboard from './components/SubmissionDashboard';
import SubmissionDetails from './components/SubmissionDetails';
import { fetchSubmissions, approveSubmission, rejectSubmission } from './services/communityService';
import { useAuth } from '../../hooks/useAuth';

export default function SubmissionsManager() {
  // --- Data State ---
  const [submissions, setSubmissions] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  const [filterStatus, setFilterStatus] = useState('all');
  
  // Modals state
  const [viewingSubmission, setViewingSubmission] = useState(null);

  // --- Data Fetching ---
  useEffect(() => {
    const loadData = async () => {
      try {
        setIsLoading(true);
        const data = await fetchSubmissions();
        setSubmissions(data);
      } catch (err) {
        setError(err.message || 'Failed to load submissions.');
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, []);

  // --- Derived State ---
  const filteredSubmissions = useMemo(() => {
    if (filterStatus === 'all') return submissions;
    return submissions.filter((s) => s.review_status === filterStatus);
  }, [submissions, filterStatus]);

  const { profile } = useAuth();
  
  // --- Handlers ---
  const handleView = (submission) => {
    setViewingSubmission(submission);
  };

  const handleClose = () => {
    setViewingSubmission(null);
  };

  const handleReject = async (submission) => {
    if (!profile || !profile.profile_id) {
      alert("Unable to determine your profile ID for this action.");
      return;
    }
    
    if (window.confirm(`Are you sure you want to reject the submission "${submission.artwork_title}"?`)) {
      try {
        const updated = await rejectSubmission(submission.artwork_submission_id, profile.profile_id);
        
        setSubmissions((prev) =>
          prev.map((s) => (s.artwork_submission_id === updated.artwork_submission_id ? updated : s))
        );
        
        if (viewingSubmission && viewingSubmission.artwork_submission_id === updated.artwork_submission_id) {
          setViewingSubmission(updated);
        }
        alert('Submission has been rejected.');
      } catch (err) {
        alert(err.message || 'Failed to reject submission.');
      }
    }
  };

  const handleApprove = async (submission) => {
    if (!profile || !profile.profile_id) {
      alert('Unable to determine your profile ID for this action.');
      return;
    }

    if (window.confirm(`Are you sure you want to approve the submission "${submission.artwork_title}"?`)) {
      try {
        const updated = await approveSubmission(submission.artwork_submission_id, profile.profile_id);

        setSubmissions((prev) =>
          prev.map((item) => (item.artwork_submission_id === updated.artwork_submission_id ? updated : item))
        );

        if (viewingSubmission?.artwork_submission_id === updated.artwork_submission_id) {
          setViewingSubmission(updated);
        }
        alert('Submission has been approved.');
      } catch (err) {
        alert(err.message || 'Failed to approve submission.');
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
      <SubmissionDashboard
        submissions={filteredSubmissions}
        filterStatus={filterStatus}
        onFilterChange={setFilterStatus}
        onView={handleView}
      />

      <SubmissionDetails
        submission={viewingSubmission}
        isOpen={!!viewingSubmission}
        onClose={handleClose}
        onApprove={handleApprove}
        onReject={handleReject}
      />
    </div>
  );
}

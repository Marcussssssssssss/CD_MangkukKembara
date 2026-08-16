import { useState } from 'react';
import CampaignsManager from '../features/community/CampaignsManager';
import SubmissionsManager from '../features/community/SubmissionsManager';
import VotingSessionsManager from '../features/community/VotingSessionsManager';

export default function HeritageCommunityPage() {
  const [activeTab, setActiveTab] = useState('campaigns');

  return (
    <div className="flex flex-col h-full">
      <div className="border-b border-surface-200 bg-white px-8 pt-6 pb-0">
        <h1 className="text-2xl font-bold text-surface-900 mb-6">Heritage Community</h1>
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('campaigns')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'campaigns'
                ? 'border-primary-600 text-primary-600'
                : 'border-transparent text-surface-500 hover:border-surface-300 hover:text-surface-700'
            }`}
          >
            Campaigns & Winners
          </button>
          <button
            onClick={() => setActiveTab('submissions')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'submissions'
                ? 'border-primary-600 text-primary-600'
                : 'border-transparent text-surface-500 hover:border-surface-300 hover:text-surface-700'
            }`}
          >
            Review Submissions
          </button>
          <button
            onClick={() => setActiveTab('voting')}
            className={`whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm transition-colors ${
              activeTab === 'voting'
                ? 'border-primary-600 text-primary-600'
                : 'border-transparent text-surface-500 hover:border-surface-300 hover:text-surface-700'
            }`}
          >
            Voting Sessions
          </button>
        </nav>
      </div>

      <div className="flex-1 overflow-auto bg-surface-50">
        {activeTab === 'campaigns' && <CampaignsManager />}
        {activeTab === 'submissions' && <SubmissionsManager />}
        {activeTab === 'voting' && <VotingSessionsManager />}
      </div>
    </div>
  );
}

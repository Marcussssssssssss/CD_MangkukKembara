import PageHeader from '../../../components/PageHeader';
import TiffinCard from './TiffinCard';

export default function TiffinDashboard({
  tiffins,
  searchQuery,
  onSearchChange,
  onCreate,
  onView,
  onEdit,
  onDeactivate,
  referenceData
}) {
  return (
    <div className="p-6 sm:p-8">
      <PageHeader
        title="Manage Heritage Tiffins"
        actions={
          <button
            onClick={onCreate}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-700"
          >
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Add New
          </button>
        }
      />

      {/* Toolbar */}
      <div className="mt-8 mb-6 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:max-w-md">
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-surface-400"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
            stroke="currentColor"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            type="text"
            placeholder="Search Tiffins"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            className="w-full rounded-lg border border-surface-200 bg-white py-2 pl-10 pr-4 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
          />
        </div>
      </div>

      {/* Cards Grid or Empty State */}
      {tiffins.length > 0 ? (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {tiffins.map(tiffin => (
            <TiffinCard
              key={tiffin.heritage_tiffin_id}
              tiffin={tiffin}
              onView={onView}
              onEdit={onEdit}
              onDeactivate={onDeactivate}
              referenceData={referenceData}
            />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-surface-300 bg-surface-50 py-16 text-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-surface-200 text-surface-500">
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m6 4.125l2.25 2.25m0 0l2.25 2.25M12 13.875l2.25-2.25M12 13.875l-2.25 2.25M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
            </svg>
          </div>
          <h3 className="mt-4 text-sm font-medium text-surface-900">No tiffins found</h3>
          <p className="mt-1 text-sm text-surface-500">
            {searchQuery ? 'Try adjusting your search query.' : 'Get started by creating a new heritage tiffin edition.'}
          </p>
          {!searchQuery && (
            <button
              onClick={onCreate}
              className="mt-6 font-medium text-primary-600 hover:text-primary-700"
            >
              Add New Edition
            </button>
          )}
        </div>
      )}
    </div>
  );
}

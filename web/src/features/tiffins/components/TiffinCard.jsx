export default function TiffinCard({ tiffin, onView, onEdit, onDeactivate, referenceData }) {
  const {
    edition_name,
    heritage_food_id,
    artwork_id,
    status,
  } = tiffin;

  const foodObj = referenceData?.foods?.find(f => f.heritage_food_id === heritage_food_id);
  const artObj = referenceData?.artworks?.find(a => a.artwork_id === artwork_id);
  const artworkImageUrl = artObj?.image_url;

  const foodName = foodObj ? foodObj.food_name : 'Unknown Food';
  const artistName = artObj && artObj.profiles ? artObj.profiles.display_name : 'Unknown Artist';
  
  const statusColors = {
    active: 'bg-green-100 text-green-700',
    draft: 'bg-yellow-100 text-yellow-700',
    inactive: 'bg-red-100 text-red-700',
  };

  const statusDisplay = status.charAt(0).toUpperCase() + status.slice(1);

  return (
    <div className="flex flex-col overflow-hidden rounded-xl border border-surface-200 bg-white shadow-sm transition-shadow hover:shadow-md">
      {/* Image Area */}
      <div
        className="relative flex h-48 w-full items-center justify-center bg-surface-100 p-3"
      >
        {artworkImageUrl ? (
          <img 
            src={artworkImageUrl}
            alt={edition_name}
            className="h-full w-full object-contain"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-primary-100 to-surface-200">
            <span className="text-sm font-medium text-surface-400">No Image</span>
          </div>
        )}
        <div className="absolute right-3 top-3">
          <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${statusColors[status] || 'bg-surface-100 text-surface-700'}`}>
            {statusDisplay}
          </span>
        </div>
      </div>

      {/* Content Area */}
      <div className="flex flex-1 flex-col p-5">
        <h3 className="text-lg font-bold text-surface-900 line-clamp-1" title={edition_name}>
          {edition_name}
        </h3>
        
        <div className="mt-3 flex-1 space-y-2 text-sm text-surface-600">
          <div className="flex items-start gap-2">
            <svg className="mt-0.5 h-4 w-4 shrink-0 text-surface-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
            </svg>
            <span className="line-clamp-1">{foodName}</span>
          </div>
          
          <div className="flex items-start gap-2">
            <svg className="mt-0.5 h-4 w-4 shrink-0 text-surface-400" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
            </svg>
            <span className="line-clamp-1">{artistName}</span>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-6 flex items-center justify-between border-t border-surface-100 pt-4">
          <div className="flex gap-2">
            <button
              onClick={() => onView(tiffin)}
              className="text-sm font-medium text-primary-600 hover:text-primary-700"
            >
              View
            </button>
            <span className="text-surface-300">•</span>
            <button
              onClick={() => onEdit(tiffin)}
              className="text-sm font-medium text-surface-600 hover:text-surface-900"
            >
              Edit
            </button>
          </div>
          
          {status !== 'inactive' && (
            <button
              onClick={() => onDeactivate(tiffin)}
              className="text-sm font-medium text-red-600 hover:text-red-700"
            >
              Deactivate
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

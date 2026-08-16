import { useState, useEffect, useRef } from 'react';
import Modal from '../../../components/Modal';
import { ALLOWED_VIDEO_TYPES, SIZE_LIMITS } from '../../../services/cloudinary/upload';

const INITIAL_FORM_STATE = {
  edition_name: '',
  description: '',
  cultural_significance: '',
  state_id: '',
  heritage_food_id: '',
  artwork_id: '',
  release_year: new Date().getFullYear(),
  status: 'draft',
  heritage_story: {
    title: '',
    story_body: ''
  }
};

export default function TiffinForm({ tiffin, isOpen, onClose, onSave, referenceData }) {
  const [formData, setFormData] = useState(INITIAL_FORM_STATE);
  const [coverImageFile, setCoverImageFile] = useState(null);
  const [heritageVideoFile, setHeritageVideoFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [isSaving, setIsSaving] = useState(false);
  const fileInputRef = useRef(null);
  const videoInputRef = useRef(null);

  useEffect(() => {
    if (tiffin && isOpen) {
      const story = tiffin.heritage_stories && tiffin.heritage_stories.length > 0 
        ? tiffin.heritage_stories[0] 
        : { title: '', story_body: '' };

      setFormData({
        edition_name: tiffin.edition_name || '',
        description: tiffin.description || '',
        cultural_significance: tiffin.cultural_significance || '',
        state_id: tiffin.state_id || '',
        heritage_food_id: tiffin.heritage_food_id || '',
        artwork_id: tiffin.artwork_id || '',
        release_year: tiffin.release_year || new Date().getFullYear(),
        status: tiffin.status || 'draft',
        heritage_story: {
          title: story.title || '',
          story_body: story.story_body || ''
        },
        // We preserve the array for updates
        heritage_stories: tiffin.heritage_stories || []
      });
      setCoverImageFile(null);
      setHeritageVideoFile(null);
      setErrors({});
    } else if (isOpen) {
      setFormData(INITIAL_FORM_STATE);
      setCoverImageFile(null);
      setHeritageVideoFile(null);
      setErrors({});
    }
  }, [tiffin, isOpen]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name.startsWith('story_')) {
      const storyField = name.replace('story_', '');
      setFormData(prev => ({
        ...prev,
        heritage_story: {
          ...prev.heritage_story,
          [storyField]: value
        }
      }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
    // Clear error for the field being edited
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      setCoverImageFile(e.target.files[0]);
    }
  };

  const handleVideoChange = (e) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      const mimeType = file.type || '';

      if (!ALLOWED_VIDEO_TYPES.has(mimeType)) {
        setErrors(prev => ({ ...prev, heritageVideo: 'Unsupported format. Please use MP4 or WebM.' }));
        e.target.value = '';
        return;
      }

      if (file.size > SIZE_LIMITS.video) {
        const limitMB = (SIZE_LIMITS.video / 1024 / 1024).toFixed(0);
        setErrors(prev => ({ ...prev, heritageVideo: `File exceeds the ${limitMB} MB size limit.` }));
        e.target.value = '';
        return;
      }

      setHeritageVideoFile(file);
      if (errors.heritageVideo) {
        setErrors(prev => ({ ...prev, heritageVideo: null }));
      }
    }
  };

  const handleRemoveVideo = () => {
    setHeritageVideoFile(null);
    if (videoInputRef.current) {
      videoInputRef.current.value = '';
    }
  };

  const validate = () => {
    const newErrors = {};
    if (!formData.edition_name.trim()) newErrors.edition_name = 'Edition name is required.';
    if (!formData.state_id) newErrors.state_id = 'State is required.';
    if (!formData.heritage_food_id) newErrors.heritage_food_id = 'Heritage food is required.';
    if (!formData.artwork_id) newErrors.artwork_id = 'Artwork is required.';
    if (!formData.heritage_story.title.trim()) newErrors['story_title'] = 'Story title is required.';
    if (!formData.heritage_story.story_body.trim()) newErrors['story_body'] = 'Story content is required.';
    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSaving(true);
    setErrors({});
    
    try {
      const payload = tiffin 
        ? { ...tiffin, ...formData } 
        : { ...formData };
        
      const files = {
        coverImage: coverImageFile,
        heritageVideo: heritageVideoFile,
      };
        
      await onSave(payload, files);
    } catch (err) {
      setErrors({ submit: err.message || 'An error occurred while saving.' });
    } finally {
      setIsSaving(false);
    }
  };

  if (!isOpen || !referenceData) return null;

  const isEditing = !!tiffin;
  const { states, foods, artworks } = referenceData;

  return (
    <Modal open={isOpen} onClose={onClose} title={isEditing ? 'Edit Heritage Tiffin' : 'Add New Heritage Tiffin'} size="lg">
      <form onSubmit={handleSubmit} className="flex flex-col max-h-[80vh]">
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {errors.submit && (
            <div className="rounded-lg border border-red-500/20 bg-red-50 p-4 text-sm text-red-600">
              {errors.submit}
            </div>
          )}

          {/* General Information */}
          <div>
            <h3 className="text-lg font-medium text-surface-900 mb-4 border-b border-surface-200 pb-2">General Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Edition Name *</label>
                <input
                  type="text"
                  name="edition_name"
                  value={formData.edition_name}
                  onChange={handleChange}
                  disabled={isSaving}
                  className={`w-full rounded-lg border ${errors.edition_name ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50 disabled:text-surface-500`}
                />
                {errors.edition_name && <p className="mt-1 text-xs text-red-500">{errors.edition_name}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Status</label>
                <select
                  name="status"
                  value={formData.status}
                  onChange={handleChange}
                  disabled={isSaving}
                  className="w-full rounded-lg border border-surface-300 px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 bg-white disabled:bg-surface-50"
                >
                  <option value="draft">Draft</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Release Year</label>
                <input
                  type="number"
                  name="release_year"
                  value={formData.release_year}
                  onChange={handleChange}
                  disabled={isSaving}
                  className="w-full rounded-lg border border-surface-300 px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Description</label>
                <textarea
                  name="description"
                  value={formData.description}
                  onChange={handleChange}
                  disabled={isSaving}
                  rows={3}
                  className="w-full rounded-lg border border-surface-300 px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Tiffin Cover Image (Cloudinary)</label>
                <input
                  type="file"
                  accept="image/jpeg, image/png, image/webp"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  disabled={isSaving}
                  className="block w-full text-sm text-surface-500
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-lg file:border-0
                    file:text-sm file:font-semibold
                    file:bg-primary-50 file:text-primary-700
                    hover:file:bg-primary-100 disabled:opacity-50"
                />
                {isEditing && tiffin.cover_image_url && !coverImageFile && (
                  <p className="mt-1 text-xs text-surface-500">Current image will be kept if no new file is selected.</p>
                )}
              </div>
            </div>
          </div>

          {/* Heritage Data */}
          <div>
            <h3 className="text-lg font-medium text-surface-900 mb-4 border-b border-surface-200 pb-2">Heritage Data</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">State *</label>
                <select
                  name="state_id"
                  value={formData.state_id}
                  onChange={handleChange}
                  disabled={isSaving}
                  className={`w-full rounded-lg border ${errors.state_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 bg-white disabled:bg-surface-50`}
                >
                  <option value="">Select State</option>
                  {states.map(state => (
                    <option key={state.state_id} value={state.state_id}>{state.state_name}</option>
                  ))}
                </select>
                {errors.state_id && <p className="mt-1 text-xs text-red-500">{errors.state_id}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Heritage Food *</label>
                <select
                  name="heritage_food_id"
                  value={formData.heritage_food_id}
                  onChange={handleChange}
                  disabled={isSaving}
                  className={`w-full rounded-lg border ${errors.heritage_food_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 bg-white disabled:bg-surface-50`}
                >
                  <option value="">Select Food</option>
                  {foods.filter(f => !formData.state_id || f.state_id === formData.state_id).map(food => (
                    <option key={food.heritage_food_id} value={food.heritage_food_id}>{food.food_name}</option>
                  ))}
                </select>
                {errors.heritage_food_id && <p className="mt-1 text-xs text-red-500">{errors.heritage_food_id}</p>}
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Cultural Significance</label>
                <textarea
                  name="cultural_significance"
                  value={formData.cultural_significance}
                  onChange={handleChange}
                  disabled={isSaving}
                  rows={2}
                  className="w-full rounded-lg border border-surface-300 px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Artwork (Artist) *</label>
                <select
                  name="artwork_id"
                  value={formData.artwork_id}
                  onChange={handleChange}
                  disabled={isSaving}
                  className={`w-full rounded-lg border ${errors.artwork_id ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 bg-white disabled:bg-surface-50`}
                >
                  <option value="">Select Artwork</option>
                  {artworks.map(art => (
                    <option key={art.artwork_id} value={art.artwork_id}>{art.title} (by {art?.profiles?.display_name || 'Unknown'})</option>
                  ))}
                </select>
                {errors.artwork_id && <p className="mt-1 text-xs text-red-500">{errors.artwork_id}</p>}
              </div>
            </div>
          </div>

          {/* Heritage Story */}
          <div>
            <h3 className="text-lg font-medium text-surface-900 mb-4 border-b border-surface-200 pb-2">Heritage Story</h3>
            <div className="grid grid-cols-1 gap-4">
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Story Title *</label>
                <input
                  type="text"
                  name="story_title"
                  value={formData.heritage_story.title}
                  onChange={handleChange}
                  disabled={isSaving}
                  className={`w-full rounded-lg border ${errors.story_title ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50`}
                />
                {errors.story_title && <p className="mt-1 text-xs text-red-500">{errors.story_title}</p>}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Story Content *</label>
                <textarea
                  name="story_story_body"
                  value={formData.heritage_story.story_body}
                  onChange={handleChange}
                  disabled={isSaving}
                  rows={4}
                  className={`w-full rounded-lg border ${errors.story_body ? 'border-red-500' : 'border-surface-300'} px-3 py-2 focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:bg-surface-50`}
                />
                {errors.story_body && <p className="mt-1 text-xs text-red-500">{errors.story_body}</p>}
              </div>

              {/* Heritage Story Video */}
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Heritage Story Video</label>
                <p className="text-xs text-surface-500 mb-2">Upload an MP4 or WebM video (max 50 MB) to accompany the heritage story.</p>
                
                {/* Show existing video info if editing and a video already exists */}
                {isEditing && tiffin?.heritage_media?.length > 0 && !heritageVideoFile && (
                  <div className="mb-3 rounded-lg border border-surface-200 bg-surface-50 p-3 flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary-50 shrink-0">
                      <svg className="h-5 w-5 text-primary-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z" />
                      </svg>
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium text-surface-900 truncate">{tiffin.heritage_media[0].title}</p>
                      <p className="text-xs text-surface-500 truncate">{tiffin.heritage_media[0].media_url}</p>
                    </div>
                    <span className="inline-flex rounded-full bg-green-100 px-2 py-0.5 text-[10px] font-semibold text-green-700">Uploaded</span>
                  </div>
                )}

                <input
                  type="file"
                  accept="video/mp4, video/webm"
                  ref={videoInputRef}
                  onChange={handleVideoChange}
                  disabled={isSaving}
                  className="block w-full text-sm text-surface-500
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-lg file:border-0
                    file:text-sm file:font-semibold
                    file:bg-primary-50 file:text-primary-700
                    hover:file:bg-primary-100 disabled:opacity-50"
                />
                {errors.heritageVideo && <p className="mt-1 text-xs text-red-500">{errors.heritageVideo}</p>}

                {heritageVideoFile && (
                  <div className="mt-2 rounded-lg border border-primary-200 bg-primary-50 p-3 flex items-center justify-between">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="flex h-8 w-8 items-center justify-center rounded bg-primary-100 shrink-0">
                        <svg className="h-4 w-4 text-primary-600" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25Z" />
                        </svg>
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-primary-900 truncate">{heritageVideoFile.name}</p>
                        <p className="text-xs text-primary-600">{(heritageVideoFile.size / 1024 / 1024).toFixed(1)} MB</p>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={handleRemoveVideo}
                      disabled={isSaving}
                      className="shrink-0 rounded-lg p-1.5 text-primary-600 hover:bg-primary-100 disabled:opacity-50"
                      title="Remove video"
                    >
                      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                )}

                {isEditing && tiffin?.heritage_media?.length > 0 && !heritageVideoFile && (
                  <p className="mt-1 text-xs text-surface-500">Current video will be kept if no new file is selected.</p>
                )}
              </div>
            </div>
          </div>
        </div>
        
        {/* Actions */}
        <div className="flex shrink-0 justify-end gap-3 border-t border-surface-200 bg-surface-50 p-6">
          <button
            type="button"
            onClick={onClose}
            disabled={isSaving}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-200 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSaving}
            className="flex items-center gap-2 rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 disabled:opacity-50"
          >
            {isSaving && (
              <svg className="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
              </svg>
            )}
            {isEditing ? 'Save Changes' : 'Create Edition'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

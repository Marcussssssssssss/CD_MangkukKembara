import { useMemo, useRef, useState } from 'react';
import Modal from '../../../components/Modal';
import { ALLOWED_VIDEO_TYPES, SIZE_LIMITS } from '../../../services/cloudinary/upload';

const STEPS = [
  { number: 1, label: 'Choose Artwork' },
  { number: 2, label: 'Tiffin Details' },
  { number: 3, label: 'Heritage Content' },
];

const INITIAL_FORM_STATE = {
  edition_name: '',
  state_id: '',
  heritage_food_id: '',
  artwork_id: '',
  release_year: new Date().getFullYear(),
  status: 'draft',
  heritage_story: {
    title: '',
    story_body: '',
  },
};

function initialFormState(tiffin) {
  if (!tiffin) return INITIAL_FORM_STATE;

  const story = tiffin.heritage_stories?.[0] || { title: '', story_body: '' };
  return {
    edition_name: tiffin.edition_name || '',
    state_id: tiffin.state_id || '',
    heritage_food_id: tiffin.heritage_food_id || '',
    artwork_id: tiffin.artwork_id || '',
    release_year: tiffin.release_year || new Date().getFullYear(),
    status: tiffin.status || 'draft',
    heritage_story: {
      title: story.title || '',
      story_body: story.story_body || '',
    },
    heritage_stories: tiffin.heritage_stories || [],
  };
}

export default function TiffinForm(props) {
  if (!props.isOpen || !props.referenceData) return null;

  const formKey = props.tiffin?.heritage_tiffin_id || 'new-tiffin';
  return <TiffinFormContent key={formKey} {...props} />;
}

function TiffinFormContent({ tiffin, isOpen, onClose, onSave, referenceData }) {
  const [formData, setFormData] = useState(() => initialFormState(tiffin));
  const [currentStep, setCurrentStep] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [heritageVideoFile, setHeritageVideoFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [isSaving, setIsSaving] = useState(false);
  const videoInputRef = useRef(null);
  const stepHeadingRef = useRef(null);

  const isEditing = !!tiffin;
  const { states, foods, artworks } = referenceData;
  const availableArtworks = artworks.filter(artwork => (
    !artwork.assigned_tiffin_id
    || artwork.assigned_tiffin_id === tiffin?.heritage_tiffin_id
  ));
  const filteredArtworks = useMemo(() => {
    const normalizedQuery = searchQuery.trim().toLowerCase();
    if (!normalizedQuery) return availableArtworks;
    return availableArtworks.filter(artwork => (
      artwork.title.toLowerCase().includes(normalizedQuery)
      || artwork.profiles?.display_name?.toLowerCase().includes(normalizedQuery)
    ));
  }, [availableArtworks, searchQuery]);
  const selectedArtwork = availableArtworks.find(
    artwork => artwork.artwork_id === formData.artwork_id
  );
  const selectedSubmission = selectedArtwork?.source_submission;
  const existingVideo = (tiffin?.heritage_media || [])
    .find(media => media.media_type === 'video');
  const filteredFoods = foods.filter(food => (
    !formData.state_id || food.state_id === formData.state_id
  ));

  const clearError = (field) => {
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: null }));
    }
  };

  const handleChange = (event) => {
    const { name, value } = event.target;
    if (name.startsWith('story_')) {
      const storyField = name === 'story_body' ? 'story_body' : name.replace('story_', '');
      setFormData(prev => ({
        ...prev,
        heritage_story: {
          ...prev.heritage_story,
          [storyField]: value,
        },
      }));
    } else if (name === 'state_id') {
      setFormData(prev => ({
        ...prev,
        state_id: value,
        heritage_food_id: prev.state_id === value ? prev.heritage_food_id : '',
      }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
    clearError(name);
  };

  const handleArtworkSelect = (artwork) => {
    const nextStateId = artwork.campaign_state_id || '';
    setFormData(prev => ({
      ...prev,
      artwork_id: artwork.artwork_id,
      state_id: nextStateId,
      heritage_food_id: prev.state_id === nextStateId ? prev.heritage_food_id : '',
    }));
    setErrors(prev => ({
      ...prev,
      artwork_id: null,
      state_id: null,
      heritage_food_id: null,
    }));
  };

  const handleVideoChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!ALLOWED_VIDEO_TYPES.has(file.type || '')) {
      setErrors(prev => ({
        ...prev,
        heritageVideo: 'Unsupported format. Please use MP4 or WebM.',
      }));
      event.target.value = '';
      return;
    }

    if (file.size > SIZE_LIMITS.video) {
      const limitMB = (SIZE_LIMITS.video / 1024 / 1024).toFixed(0);
      setErrors(prev => ({
        ...prev,
        heritageVideo: `File exceeds the ${limitMB} MB size limit.`,
      }));
      event.target.value = '';
      return;
    }

    setHeritageVideoFile(file);
    setErrors(prev => ({ ...prev, heritageVideo: null }));
  };

  const handleRemoveVideo = () => {
    setHeritageVideoFile(null);
    if (videoInputRef.current) videoInputRef.current.value = '';
  };

  const validateStep = (step) => {
    const nextErrors = {};
    if (step === 1 && !formData.artwork_id) {
      nextErrors.artwork_id = 'Select a published winning Artwork to continue.';
    }
    if (step === 2) {
      if (!formData.edition_name.trim()) nextErrors.edition_name = 'Edition name is required.';
      if (!formData.state_id) nextErrors.state_id = 'State is required.';
      if (!formData.heritage_food_id) nextErrors.heritage_food_id = 'Heritage food is required.';
    }
    if (step === 3) {
      if (!formData.heritage_story.title.trim()) nextErrors.story_title = 'Story title is required.';
      if (!formData.heritage_story.story_body.trim()) nextErrors.story_body = 'Story content is required.';
    }
    return nextErrors;
  };

  const focusStepHeading = () => {
    requestAnimationFrame(() => stepHeadingRef.current?.focus());
  };

  const handleNext = () => {
    const validationErrors = validateStep(currentStep);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(prev => ({ ...prev, ...validationErrors }));
      return;
    }
    setErrors({});
    setCurrentStep(step => Math.min(step + 1, STEPS.length));
    focusStepHeading();
  };

  const handleBack = () => {
    setErrors({});
    setCurrentStep(step => Math.max(step - 1, 1));
    focusStepHeading();
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    const validationErrors = {
      ...validateStep(1),
      ...validateStep(2),
      ...validateStep(3),
    };
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      const firstInvalidStep = validationErrors.artwork_id
        ? 1
        : validationErrors.edition_name || validationErrors.state_id || validationErrors.heritage_food_id
          ? 2
          : 3;
      setCurrentStep(firstInvalidStep);
      focusStepHeading();
      return;
    }

    setIsSaving(true);
    setErrors({});
    try {
      const payload = tiffin ? { ...tiffin, ...formData } : { ...formData };
      await onSave(payload, { heritageVideo: heritageVideoFile });
    } catch (error) {
      setErrors({ submit: error.message || 'An error occurred while saving.' });
      setIsSaving(false);
    }
  };

  return (
    <Modal
      open={isOpen}
      onClose={isSaving ? undefined : onClose}
      title={isEditing ? 'Edit Heritage Tiffin' : 'Create Heritage Tiffin'}
      size="xl"
    >
      <form onSubmit={handleSubmit} className="flex max-h-[85vh] flex-col">
        <StepIndicator currentStep={currentStep} />

        <div className="flex-1 overflow-y-auto p-6">
          {errors.submit && (
            <div className="mb-6 rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
              {errors.submit}
            </div>
          )}

          <div ref={stepHeadingRef} tabIndex={-1} className="focus:outline-none">
            {currentStep === 1 && (
              <ArtworkStep
                artworks={filteredArtworks}
                selectedArtwork={selectedArtwork}
                selectedSubmission={selectedSubmission}
                searchQuery={searchQuery}
                onSearchChange={setSearchQuery}
                onSelect={handleArtworkSelect}
                error={errors.artwork_id}
              />
            )}

            {currentStep === 2 && (
              <TiffinDetailsStep
                formData={formData}
                states={states}
                foods={filteredFoods}
                errors={errors}
                onChange={handleChange}
                artwork={selectedArtwork}
              />
            )}

            {currentStep === 3 && (
              <HeritageContentStep
                formData={formData}
                errors={errors}
                existingVideo={existingVideo}
                heritageVideoFile={heritageVideoFile}
                videoInputRef={videoInputRef}
                onChange={handleChange}
                onVideoChange={handleVideoChange}
                onRemoveVideo={handleRemoveVideo}
              />
            )}
          </div>
        </div>

        <div className="flex shrink-0 items-center justify-between border-t border-surface-200 bg-surface-50 p-5">
          <button
            type="button"
            onClick={onClose}
            disabled={isSaving}
            className="rounded-lg px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-200 disabled:opacity-50"
          >
            Cancel
          </button>

          <div className="flex items-center gap-3">
            {currentStep > 1 && (
              <button
                type="button"
                onClick={handleBack}
                disabled={isSaving}
                className="rounded-lg border border-surface-300 bg-white px-4 py-2 text-sm font-medium text-surface-700 hover:bg-surface-50 disabled:opacity-50"
              >
                Back
              </button>
            )}
            {currentStep < STEPS.length ? (
              <button
                type="button"
                onClick={handleNext}
                disabled={isSaving}
                className="rounded-lg bg-primary-600 px-5 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
              >
                Continue
              </button>
            ) : (
              <button
                type="submit"
                disabled={isSaving}
                className="rounded-lg bg-primary-600 px-5 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
              >
                {isSaving ? 'Saving…' : isEditing ? 'Save Changes' : 'Create Tiffin'}
              </button>
            )}
          </div>
        </div>
      </form>
    </Modal>
  );
}

function StepIndicator({ currentStep }) {
  return (
    <ol className="grid grid-cols-3 border-b border-surface-200 bg-white px-6 py-4">
      {STEPS.map(step => {
        const isCurrent = step.number === currentStep;
        const isComplete = step.number < currentStep;
        return (
          <li key={step.number} className="flex items-center gap-2">
            <span className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold ${
              isCurrent || isComplete
                ? 'bg-primary-600 text-white'
                : 'bg-surface-100 text-surface-500'
            }`}>
              {isComplete ? '✓' : step.number}
            </span>
            <span className={`hidden text-sm font-medium sm:inline ${
              isCurrent ? 'text-primary-700' : 'text-surface-500'
            }`}>
              {step.label}
            </span>
          </li>
        );
      })}
    </ol>
  );
}

function ArtworkStep({
  artworks,
  selectedArtwork,
  selectedSubmission,
  searchQuery,
  onSearchChange,
  onSelect,
  error,
}) {
  return (
    <section>
      <h3 className="text-xl font-bold text-surface-900">Choose the Tiffin Artwork</h3>
      <p className="mt-1 text-sm text-surface-600">
        Select one published, unassigned campaign winner. Its image and cultural meanings will become part of the Tiffin experience.
      </p>

      <label className="mt-5 block">
        <span className="text-sm font-medium text-surface-700">Search Artwork</span>
        <input
          type="search"
          value={searchQuery}
          onChange={event => onSearchChange(event.target.value)}
          placeholder="Search by title or creator"
          className="mt-2 w-full rounded-lg border border-surface-300 px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500"
        />
      </label>

      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}

      <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {artworks.map(artwork => {
          const isSelected = artwork.artwork_id === selectedArtwork?.artwork_id;
          return (
            <button
              key={artwork.artwork_id}
              type="button"
              aria-pressed={isSelected}
              onClick={() => onSelect(artwork)}
              className={`overflow-hidden rounded-xl border bg-white text-left transition focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 ${
                isSelected
                  ? 'border-primary-500 ring-2 ring-primary-100'
                  : 'border-surface-200 hover:border-primary-300 hover:shadow-md'
              }`}
            >
              <div className="aspect-[4/3] bg-surface-100">
                <img src={artwork.image_url} alt={artwork.title} className="h-full w-full object-cover" />
              </div>
              <div className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-bold text-surface-900">{artwork.title}</p>
                    <p className="mt-1 text-sm text-surface-500">
                      By {artwork.profiles?.display_name || 'Unknown creator'}
                    </p>
                  </div>
                  {isSelected && (
                    <span className="rounded-full bg-primary-100 px-2 py-1 text-xs font-semibold text-primary-700">
                      Selected
                    </span>
                  )}
                </div>
              </div>
            </button>
          );
        })}
      </div>

      {artworks.length === 0 && (
        <div className="mt-5 rounded-xl border border-dashed border-surface-300 bg-surface-50 p-8 text-center">
          <p className="text-sm text-surface-600">No matching unassigned winning Artwork is available.</p>
        </div>
      )}

      {selectedArtwork && (
        <div className="mt-6 overflow-hidden rounded-xl border border-primary-200 bg-primary-50/30">
          <div className="grid grid-cols-1 md:grid-cols-[15rem_1fr]">
            <img
              src={selectedArtwork.image_url}
              alt={selectedArtwork.title}
              className="h-full min-h-60 w-full object-cover"
            />
            <div className="space-y-5 p-5">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-primary-600">Selected Artwork</p>
                <h4 className="mt-1 text-lg font-bold text-surface-900">{selectedArtwork.title}</h4>
                <p className="mt-1 text-sm text-surface-600">
                  Designed by {selectedArtwork.profiles?.display_name || 'Unknown creator'}
                </p>
              </div>
              <ArtworkDetail label="Design Description" value={selectedSubmission?.design_description} />
              <ArtworkDetail label="Cultural Inspiration" value={selectedSubmission?.cultural_inspiration} />
              <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
                <ArtworkDetail label="Layer 1 Meaning" value={selectedSubmission?.layer_1_meaning} />
                <ArtworkDetail label="Layer 2 Meaning" value={selectedSubmission?.layer_2_meaning} />
                <ArtworkDetail label="Layer 3 Meaning" value={selectedSubmission?.layer_3_meaning} />
              </div>
              <p className="text-xs text-surface-500">
                This information comes from the winning submission and is read-only.
              </p>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}

function TiffinDetailsStep({ formData, states, foods, errors, onChange, artwork }) {
  const selectedState = states.find(state => state.state_id === formData.state_id);

  return (
    <section>
      <h3 className="text-xl font-bold text-surface-900">Enter Tiffin Details</h3>
      <p className="mt-1 text-sm text-surface-600">
        Add only information specific to this Tiffin edition. Artwork information is already linked.
      </p>

      {artwork && (
        <div className="mt-5 flex items-center gap-3 rounded-lg border border-surface-200 bg-surface-50 p-3">
          <img src={artwork.image_url} alt="" className="h-14 w-14 rounded-lg object-cover" />
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-surface-400">Selected Artwork</p>
            <p className="font-semibold text-surface-900">{artwork.title}</p>
          </div>
        </div>
      )}

      <div className="mt-6 grid grid-cols-1 gap-5 md:grid-cols-2">
        <FormField label="Edition Name" error={errors.edition_name} className="md:col-span-2">
          <input
            type="text"
            name="edition_name"
            value={formData.edition_name}
            onChange={onChange}
            className={inputClass(errors.edition_name)}
          />
        </FormField>

        <FormField label="Release Year" required={false}>
          <input
            type="number"
            name="release_year"
            min="2000"
            max="2100"
            value={formData.release_year}
            onChange={onChange}
            className={inputClass()}
          />
        </FormField>

        <FormField label="Status">
          <select name="status" value={formData.status} onChange={onChange} className={inputClass()}>
            <option value="draft">Draft</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
        </FormField>

        <FormField label="State" error={errors.state_id}>
          <div className={`${inputClass(errors.state_id)} bg-surface-100 text-surface-700`}>
            {selectedState?.state_name || 'No campaign state is linked to this Artwork'}
          </div>
          <p className="mt-1 text-xs text-surface-500">
            Set automatically from the winning Artwork campaign.
          </p>
        </FormField>

        <FormField label="Featured Heritage Food" error={errors.heritage_food_id}>
          <select
            name="heritage_food_id"
            value={formData.heritage_food_id}
            onChange={onChange}
            disabled={!formData.state_id}
            className={inputClass(errors.heritage_food_id)}
          >
            <option value="">{formData.state_id ? 'Select a heritage food' : 'Choose an Artwork first'}</option>
            {foods.map(food => (
              <option key={food.heritage_food_id} value={food.heritage_food_id}>{food.food_name}</option>
            ))}
          </select>
          {formData.state_id && foods.length === 0 && (
            <p className="mt-1 text-xs text-amber-700">
              No active heritage food is configured for this campaign state.
            </p>
          )}
        </FormField>
      </div>
    </section>
  );
}

function HeritageContentStep({
  formData,
  errors,
  existingVideo,
  heritageVideoFile,
  videoInputRef,
  onChange,
  onVideoChange,
  onRemoveVideo,
}) {
  return (
    <section>
      <h3 className="text-xl font-bold text-surface-900">Add Heritage Content</h3>
      <p className="mt-1 text-sm text-surface-600">
        Add one heritage story and an optional video for the complete Tiffin experience.
      </p>

      <div className="mt-6 space-y-5">
        <FormField label="Story Title" error={errors.story_title}>
          <input
            type="text"
            name="story_title"
            value={formData.heritage_story.title}
            onChange={onChange}
            className={inputClass(errors.story_title)}
          />
        </FormField>

        <FormField label="Story Content" error={errors.story_body}>
          <textarea
            name="story_body"
            value={formData.heritage_story.story_body}
            onChange={onChange}
            rows={8}
            className={inputClass(errors.story_body)}
          />
        </FormField>

        <FormField label="Heritage Video" error={errors.heritageVideo} required={false}>
          {existingVideo && !heritageVideoFile && (
            <div className="mb-3 rounded-lg border border-surface-200 bg-surface-50 p-3">
              <p className="text-sm font-medium text-surface-900">{existingVideo.title}</p>
              <p className="mt-1 truncate text-xs text-surface-500">{existingVideo.media_url}</p>
              <p className="mt-2 text-xs text-surface-600">
                Uploading a new video will replace this video.
              </p>
            </div>
          )}
          <input
            ref={videoInputRef}
            type="file"
            accept="video/mp4,video/webm"
            onChange={onVideoChange}
            className="block w-full rounded-lg border border-surface-300 bg-white px-3 py-2 text-sm text-surface-600 file:mr-4 file:rounded-md file:border-0 file:bg-primary-50 file:px-3 file:py-2 file:font-semibold file:text-primary-700 hover:file:bg-primary-100"
          />
          <p className="mt-1 text-xs text-surface-500">MP4 or WebM, maximum 50 MB.</p>

          {heritageVideoFile && (
            <div className="mt-3 flex items-center justify-between rounded-lg border border-primary-200 bg-primary-50 p-3">
              <div>
                <p className="text-sm font-medium text-primary-900">{heritageVideoFile.name}</p>
                <p className="text-xs text-primary-700">
                  {(heritageVideoFile.size / 1024 / 1024).toFixed(1)} MB
                </p>
              </div>
              <button
                type="button"
                onClick={onRemoveVideo}
                className="rounded-lg px-3 py-1.5 text-sm font-medium text-primary-700 hover:bg-primary-100"
              >
                Remove
              </button>
            </div>
          )}
        </FormField>
      </div>
    </section>
  );
}

function FormField({ label, error, required = true, className = '', children }) {
  return (
    <label className={`block ${className}`}>
      <span className="text-sm font-medium text-surface-700">
        {label}{required && <span className="text-red-500" aria-hidden="true"> *</span>}
      </span>
      <div className="mt-2">{children}</div>
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </label>
  );
}

function ArtworkDetail({ label, value }) {
  return (
    <div>
      <p className="text-xs font-semibold uppercase tracking-wider text-surface-400">{label}</p>
      <p className="mt-1 whitespace-pre-wrap text-sm text-surface-700">{value || 'Not provided.'}</p>
    </div>
  );
}

function inputClass(hasError) {
  return `w-full rounded-lg border ${hasError ? 'border-red-500' : 'border-surface-300'} bg-white px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:cursor-not-allowed disabled:bg-surface-100`;
}

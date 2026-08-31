export const TIFFIN_STATUSES = new Set(['draft', 'active', 'inactive']);
export const TIFFIN_RELEASE_YEAR_MIN = 2000;
export const TIFFIN_RELEASE_YEAR_MAX = 2100;

export function validateTiffinInput(formData) {
  const errors = {};
  const editionName = formData?.edition_name?.trim() || '';
  const storyTitle = formData?.heritage_story?.title?.trim() || '';
  const storyBody = formData?.heritage_story?.story_body?.trim() || '';
  const releaseYear = formData?.release_year;

  if (!/^A[0-9]{4}$/.test(formData?.artwork_id || '')) {
    errors.artwork_id = 'Select a published winning Artwork to continue.';
  }
  if (!editionName) {
    errors.edition_name = 'Tiffin edition name is required.';
  } else if (editionName.length > 150) {
    errors.edition_name = 'Tiffin edition name must not exceed 150 characters.';
  }
  if (!/^S[0-9]{4}$/.test(formData?.state_id || '')) {
    errors.state_id = 'A valid Artwork campaign state is required.';
  }
  if (!/^HF[0-9]{4}$/.test(formData?.heritage_food_id || '')) {
    errors.heritage_food_id = 'Select a valid Heritage Food.';
  }
  if (releaseYear !== '' && releaseYear !== null && releaseYear !== undefined) {
    const numericYear = Number(releaseYear);
    if (
      !Number.isInteger(numericYear)
      || numericYear < TIFFIN_RELEASE_YEAR_MIN
      || numericYear > TIFFIN_RELEASE_YEAR_MAX
    ) {
      errors.release_year = `Release year must be between ${TIFFIN_RELEASE_YEAR_MIN} and ${TIFFIN_RELEASE_YEAR_MAX}.`;
    }
  }
  if (!TIFFIN_STATUSES.has(formData?.status)) {
    errors.status = 'Select a valid Tiffin status.';
  }
  if (!storyTitle) {
    errors.story_title = 'Story title is required.';
  } else if (storyTitle.length > 180) {
    errors.story_title = 'Story title must not exceed 180 characters.';
  }
  if (!storyBody) {
    errors.story_body = 'Story content is required.';
  }

  return errors;
}

export function firstTiffinValidationMessage(errors) {
  const fieldOrder = [
    'artwork_id',
    'edition_name',
    'release_year',
    'status',
    'state_id',
    'heritage_food_id',
    'story_title',
    'story_body',
  ];
  for (const field of fieldOrder) {
    if (errors[field]) return errors[field];
  }
  return 'Review the highlighted Tiffin information.';
}

export function validateHeritageFoodInput(foodData) {
  const errors = {};
  const foodName = foodData?.food_name?.trim() || '';
  const originSummary = foodData?.origin_summary?.trim() || '';
  const culturalSignificance = foodData?.cultural_significance?.trim() || '';

  if (!foodName) {
    errors.food_name = 'Food name is required.';
  } else if (foodName.length > 150) {
    errors.food_name = 'Food name must not exceed 150 characters.';
  }
  if (!/^S[0-9]{4}$/.test(foodData?.state_id || '')) {
    errors.state_id = 'A valid state is required.';
  }
  if (!/^FC[0-9]{4}$/.test(foodData?.food_category_id || '')) {
    errors.food_category_id = 'Select a valid Food Category.';
  }
  if (originSummary.length > 5000) {
    errors.origin_summary = 'Origin summary must not exceed 5,000 characters.';
  }
  if (culturalSignificance.length > 5000) {
    errors.cultural_significance = 'Cultural significance must not exceed 5,000 characters.';
  }
  return errors;
}

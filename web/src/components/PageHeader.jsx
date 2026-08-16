/**
 * Consistent page header used across all Admin pages.
 *
 * @param {Object}             props
 * @param {string}             props.title       — Page heading.
 * @param {string}             [props.description] — Optional subtitle / description.
 * @param {import('react').ReactNode} [props.actions] — Optional right-aligned action buttons.
 */
export default function PageHeader({ title, description, actions }) {
  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold text-surface-900">{title}</h1>
        {description && (
          <p className="mt-1 text-sm text-surface-500">{description}</p>
        )}
      </div>
      {actions && <div className="flex shrink-0 gap-2">{actions}</div>}
    </div>
  );
}

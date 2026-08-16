import { useEffect, useRef, useCallback } from 'react';

/**
 * Reusable modal dialog.
 *
 * Features:
 *  - Backdrop click to close
 *  - Escape key to close
 *  - Scroll lock on body while open
 *  - Configurable width (sm / md / lg / xl / full)
 *
 * @param {Object}  props
 * @param {boolean} props.open     — Whether the modal is visible.
 * @param {() => void} props.onClose — Called when the modal requests to close.
 * @param {string}  [props.title]  — Optional header title.
 * @param {'sm'|'md'|'lg'|'xl'|'full'} [props.size] — Max-width preset.
 * @param {import('react').ReactNode} props.children
 */
export default function Modal({ open, onClose, title, size = 'md', children }) {
  const overlayRef = useRef(null);

  const stableOnClose = useCallback(() => onClose(), [onClose]);

  useEffect(() => {
    if (!open) return;

    const handleEsc = (e) => {
      if (e.key === 'Escape') stableOnClose();
    };

    document.addEventListener('keydown', handleEsc);
    document.body.style.overflow = 'hidden';

    return () => {
      document.removeEventListener('keydown', handleEsc);
      document.body.style.overflow = '';
    };
  }, [open, stableOnClose]);

  if (!open) return null;

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-2xl',
    lg: 'max-w-4xl',
    xl: 'max-w-6xl',
    full: 'max-w-[calc(100vw-2rem)]',
  };

  return (
    <div
      ref={overlayRef}
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/50 p-4 backdrop-blur-sm sm:items-center"
      onClick={(e) => {
        if (e.target === overlayRef.current) stableOnClose();
      }}
    >
      <div
        className={`my-8 w-full ${sizeClasses[size] || sizeClasses.md} rounded-xl bg-white shadow-2xl sm:my-0`}
        role="dialog"
        aria-modal="true"
        aria-label={title || 'Dialog'}
      >
        {title && (
          <div className="flex items-center justify-between border-b border-surface-200 px-6 py-4">
            <h2 className="text-lg font-semibold text-surface-900">{title}</h2>
            <button
              type="button"
              onClick={stableOnClose}
              className="rounded-lg p-1.5 text-surface-400 transition-colors hover:bg-surface-100 hover:text-surface-600"
              aria-label="Close"
            >
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        )}
        {children}
      </div>
    </div>
  );
}

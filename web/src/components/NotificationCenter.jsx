const notificationStyles = {
  success: {
    title: 'Success',
    border: 'border-green-200',
    iconBackground: 'bg-green-100',
    iconColor: 'text-green-700',
  },
  error: {
    title: 'Operation failed',
    border: 'border-red-200',
    iconBackground: 'bg-red-100',
    iconColor: 'text-red-700',
  },
};

function StatusIcon({ type }) {
  if (type === 'error') {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
        <circle cx="12" cy="12" r="9" />
        <path d="M12 7v6" strokeLinecap="round" />
        <path d="M12 17h.01" strokeLinecap="round" />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="12" cy="12" r="9" />
      <path d="m8 12 2.5 2.5L16 9" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export default function NotificationCenter({ notifications, onDismiss }) {
  if (notifications.length === 0) return null;

  return (
    <section
      className="pointer-events-none fixed inset-x-4 top-4 z-[100] flex flex-col gap-3 sm:left-auto sm:right-4 sm:w-full sm:max-w-sm"
      aria-label="Operation notifications"
    >
      {notifications.map((notification) => {
        const styles = notificationStyles[notification.type] || notificationStyles.success;
        const isError = notification.type === 'error';

        return (
          <div
            key={notification.id}
            className={`pointer-events-auto flex items-start gap-3 rounded-xl border ${styles.border} bg-white p-4 shadow-lg`}
            role={isError ? 'alert' : 'status'}
            aria-live={isError ? 'assertive' : 'polite'}
            aria-atomic="true"
          >
            <div className={`mt-0.5 h-8 w-8 shrink-0 rounded-full p-1.5 ${styles.iconBackground} ${styles.iconColor}`}>
              <StatusIcon type={notification.type} />
            </div>

            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-surface-900">{styles.title}</p>
              <p className="mt-0.5 break-words text-sm leading-5 text-surface-600">
                {notification.message}
              </p>
            </div>

            <button
              type="button"
              className="-mr-1 -mt-1 rounded-md p-1.5 text-surface-400 transition-colors hover:bg-surface-100 hover:text-surface-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-1"
              onClick={() => onDismiss(notification.id)}
              aria-label={`Dismiss ${styles.title.toLowerCase()} notification`}
            >
              <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="m6 6 12 12M18 6 6 18" strokeLinecap="round" />
              </svg>
            </button>
          </div>
        );
      })}
    </section>
  );
}

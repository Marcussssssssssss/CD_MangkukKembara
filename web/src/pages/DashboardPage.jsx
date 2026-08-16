import { Link } from 'react-router-dom';
import PageHeader from '../components/PageHeader';

/**
 * Admin dashboard — landing page after sign-in.
 *
 * Displays summary cards that link to each management module.
 * Module-specific data will replace the placeholder counts
 * once the feature services are connected.
 */

const MODULE_CARDS = [
  {
    title: 'Heritage Tiffins',
    description: 'Manage heritage tiffin carrier editions, stories, media, and QR codes.',
    to: '/tiffins',
    color: 'primary',
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z"
      />
    ),
  },
  {
    title: 'Heritage Food Vendors',
    description: 'Manage vendor locations, operating hours, menus, and tiffin availability.',
    to: '/vendors',
    color: 'accent',
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72m-13.5 8.65h3.75a.75.75 0 00.75-.75V13.5a.75.75 0 00-.75-.75H6.75a.75.75 0 00-.75.75v3.75c0 .415.336.75.75.75z"
      />
    ),
  },
];

const COLOR_MAP = {
  primary: {
    bg: 'bg-primary-50',
    icon: 'bg-primary-100 text-primary-600',
    hover: 'hover:border-primary-300',
    link: 'text-primary-600 hover:text-primary-700',
  },
  accent: {
    bg: 'bg-accent-50',
    icon: 'bg-accent-100 text-accent-600',
    hover: 'hover:border-accent-300',
    link: 'text-accent-600 hover:text-accent-700',
  },
};

export default function DashboardPage() {
  return (
    <div className="p-6 sm:p-8">
      <PageHeader
        title="Dashboard"
        description="Welcome to the MangkukKembara admin panel."
      />

      {/* Module cards */}
      <div className="mt-8 grid gap-6 sm:grid-cols-2">
        {MODULE_CARDS.map((card) => {
          const colors = COLOR_MAP[card.color];
          return (
            <Link
              key={card.to}
              to={card.to}
              className={`group rounded-xl border border-surface-200 bg-white p-6 shadow-sm transition-all ${colors.hover} hover:shadow-md`}
            >
              <div className="flex items-start gap-4">
                <div
                  className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-lg ${colors.icon}`}
                >
                  <svg
                    className="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    strokeWidth={1.5}
                    stroke="currentColor"
                  >
                    {card.icon}
                  </svg>
                </div>
                <div className="min-w-0 flex-1">
                  <h2 className="text-lg font-semibold text-surface-800">
                    {card.title}
                  </h2>
                  <p className="mt-1 text-sm text-surface-500">
                    {card.description}
                  </p>
                  <span
                    className={`mt-3 inline-flex items-center gap-1 text-sm font-medium ${colors.link}`}
                  >
                    Open module
                    <svg
                      className="h-4 w-4 transition-transform group-hover:translate-x-0.5"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth={2}
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
                      />
                    </svg>
                  </span>
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

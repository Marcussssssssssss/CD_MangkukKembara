import { useState } from 'react';
import { Navigate, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

/**
 * Login page — shown when the user is not authenticated.
 *
 * Redirects to the originally requested page (or /) on successful sign-in.
 */
export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const { signIn, isAuthenticated, isAdmin, loading, user, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from?.pathname;
  const target = (from && from !== '/' && from !== '/login') ? from : '/tiffins';

  // ── Auth still loading → spinner ──
  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-surface-900">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-surface-600 border-t-primary-500" />
      </div>
    );
  }

  if (isAuthenticated && isAdmin) {
    return <Navigate to={target} replace />;
  }

  // ── Form submit handler ──
  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await signIn(email, password);
      navigate(target, { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-surface-900 via-surface-800 to-primary-950 px-4">
      <div className="w-full max-w-md">
        {/* Branding */}
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-white">
            Mangkuk<span className="text-primary-400">Kembara</span>
          </h1>
          <p className="mt-2 text-sm text-surface-400">
            Sign in to the admin panel
          </p>
        </div>

        {/* Card */}
        <div className="rounded-2xl border border-white/10 bg-white/5 p-8 shadow-2xl backdrop-blur-xl">
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Non-Admin Notice */}
            {isAuthenticated && !isAdmin && (
              <div className="rounded-lg border border-yellow-500/20 bg-yellow-500/10 px-4 py-4 text-sm text-yellow-200">
                <p className="mb-3">
                  You are currently signed in as <strong className="font-semibold text-white">{user?.email}</strong>. This account does not have administrator privileges.
                </p>
                <div className="flex justify-end">
                  <button
                    type="button"
                    onClick={() => signOut()}
                    className="rounded bg-yellow-500/20 px-3 py-1.5 text-xs font-semibold text-yellow-100 hover:bg-yellow-500/30 transition-colors"
                  >
                    Sign Out
                  </button>
                </div>
              </div>
            )}

            {/* Error banner */}
            {error && (
              <div className="rounded-lg border border-red-500/20 bg-red-500/10 px-4 py-3 text-sm text-red-400">
                {error}
              </div>
            )}

            {/* Email */}
            <div>
              <label
                htmlFor="login-email"
                className="mb-1.5 block text-sm font-medium text-surface-300"
              >
                Email
              </label>
              <input
                id="login-email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-white placeholder-surface-500 transition-all focus:border-primary-500/50 focus:outline-none focus:ring-2 focus:ring-primary-500/40"
              />
            </div>

            {/* Password */}
            <div>
              <label
                htmlFor="login-password"
                className="mb-1.5 block text-sm font-medium text-surface-300"
              >
                Password
              </label>
              <input
                id="login-password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-white placeholder-surface-500 transition-all focus:border-primary-500/50 focus:outline-none focus:ring-2 focus:ring-primary-500/40"
              />
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={submitting}
              className="w-full rounded-lg bg-primary-600 px-4 py-2.5 font-medium text-white transition-all hover:bg-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/50 focus:ring-offset-2 focus:ring-offset-surface-900 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {submitting ? 'Signing in\u2026' : 'Sign in'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

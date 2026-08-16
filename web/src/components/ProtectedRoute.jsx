import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

/**
 * Route guard that redirects unauthenticated users to /login.
 *
 * While the auth state is still loading (initial session check), a
 * centered spinner is shown to prevent a flash of the login page.
 */
export default function ProtectedRoute({ children }) {
  const { isAuthenticated, isAdmin, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-surface-50">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-surface-300 border-t-primary-600" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (!isAdmin) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-surface-50 p-6 text-center">
        <h2 className="mb-2 text-2xl font-bold text-red-600">Access Denied</h2>
        <p className="mb-6 text-surface-600">
          You do not have administrator privileges to view this portal.
        </p>
      </div>
    );
  }

  return children;
}

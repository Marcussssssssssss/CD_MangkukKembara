import { Routes, Route, Navigate } from 'react-router-dom';
import AdminLayout from './layouts/AdminLayout';
import ProtectedRoute from './components/ProtectedRoute';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import ManageTiffinsPage from './pages/ManageTiffinsPage';
import ManageVendorsPage from './pages/ManageVendorsPage';
import HeritageCommunityPage from './pages/HeritageCommunityPage';

/**
 * Application root — defines the route tree.
 *
 * Route conventions:
 *  - /login      → public, unauthenticated
 *  - /           → protected, Admin Dashboard
 *  - /tiffins    → protected, Manage Heritage Tiffins (UC500)
 *  - /vendors    → protected, Manage Heritage Food Vendors (UC600)
 *  - /community  → protected, Manage Heritage Community
 *  - *           → fallback redirect to /
 */
function App() {
  return (
    <Routes>
      {/* Public route */}
      <Route path="/" element={<Navigate to="/login" replace />} />
      <Route path="/login" element={<LoginPage />} />

      {/* Protected routes — wrapped in AdminLayout */}
      <Route
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/tiffins" element={<ManageTiffinsPage />} />
        <Route path="/vendors" element={<ManageVendorsPage />} />
        <Route path="/community" element={<HeritageCommunityPage />} />
        {/* ── Future feature routes ── */}
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

export default App;

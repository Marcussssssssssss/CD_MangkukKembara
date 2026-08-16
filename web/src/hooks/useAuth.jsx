import { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { supabase } from '../services/supabase/client';

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

const AuthContext = createContext(null);

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/**
 * Wraps the application tree and keeps Supabase Auth session state in sync.
 *
 * Provides:
 *  - session / user / loading / isAuthenticated
 *  - signIn, signUp, signOut helpers
 */
export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const fetchProfile = async (userId) => {
      try {
        const { data, error } = await supabase
          .from('profiles')
          .select('*')
          .eq('auth_user_id', userId)
          .single();
        
        if (isMounted) {
          if (!error && data) {
            setProfile(data);
            setIsAdmin(data.role === 'admin' && data.is_active === true);
          } else {
            setProfile(null);
            setIsAdmin(false);
          }
        }
      } catch (err) {
        if (isMounted) {
          setProfile(null);
          setIsAdmin(false);
        }
      }
    };

    // Fetch the current session on mount.
    supabase.auth
      .getSession()
      .then(async ({ data: { session: currentSession } }) => {
        if (!isMounted) return;
        setSession(currentSession);
        setUser(currentSession?.user ?? null);
        if (currentSession?.user) {
          await fetchProfile(currentSession.user.id);
        }
      })
      .catch(() => {
        // Supabase may not be reachable
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    // Subscribe to future auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, updatedSession) => {
      if (!isMounted) return;
      setSession(updatedSession);
      setUser(updatedSession?.user ?? null);
      
      if (updatedSession?.user) {
        if (event === 'SIGNED_IN') setLoading(true);
        await fetchProfile(updatedSession.user.id);
      } else {
        setProfile(null);
        setIsAdmin(false);
      }
      if (isMounted) setLoading(false);
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, []);

  // --- Auth helpers --------------------------------------------------------

  const signIn = async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    return data;
  };

  const signUp = async (email, password, metadata = {}) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: metadata },
    });
    if (error) throw error;
    return data;
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  };

  // --- Memoised value to prevent unnecessary re-renders --------------------

  const value = useMemo(
    () => ({
      session,
      user,
      profile,
      isAdmin,
      loading,
      isAuthenticated: !!session,
      signIn,
      signUp,
      signOut,
    }),
    [session, user, profile, isAdmin, loading]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// ---------------------------------------------------------------------------
// Hook
// ---------------------------------------------------------------------------

/**
 * Access the current auth state and helpers.
 *
 * Must be called inside an <AuthProvider>.
 */
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an <AuthProvider>.');
  }
  return context;
}

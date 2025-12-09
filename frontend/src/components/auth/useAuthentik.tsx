import { useAuth } from 'react-oidc-context';
import type { User } from 'oidc-client-ts';

interface AuthentikUser extends User {
  // Add any Authentik-specific user properties
  groups?: string[];
  is_staff?: boolean;
  is_superuser?: boolean;
}

export const useAuthentik = () => {
  const auth = useAuth();

  const login = () => {
    auth.signinRedirect();
  };

  const logout = () => {
    auth.signoutRedirect();
  };

  const getAccessToken = () => {
    return auth.user?.access_token;
  };

  const isAuthenticated = () => {
    return auth.isAuthenticated;
  };

  const getUserGroups = (): string[] => {
    const user = auth.user as AuthentikUser;
    return user?.groups || [];
  };

  const hasGroup = (group: string): boolean => {
    return getUserGroups().includes(group);
  };

  const isAdmin = (): boolean => {
    const user = auth.user as AuthentikUser;
    return user?.is_staff || user?.is_superuser || false;
  };

  return {
    // Auth state
    user: auth.user as AuthentikUser | null,
    isLoading: auth.isLoading,
    error: auth.error,
    isAuthenticated: auth.isAuthenticated,
    
    // Auth methods
    login,
    logout,
    getAccessToken,
    
    // Authentik-specific helpers
    getUserGroups,
    hasGroup,
    isAdmin,
    
    // Raw auth object for advanced usage
    rawAuth: auth,
  };
};

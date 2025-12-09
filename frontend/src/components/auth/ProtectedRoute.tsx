import React from 'react';
import { useAuthentik } from './useAuthentik';
import type { ReactNode } from 'react';

interface ProtectedRouteProps {
  children: ReactNode;
  requiredGroups?: string[];
  requireAdmin?: boolean;
  fallback?: ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  requiredGroups = [],
  requireAdmin = false,
  fallback = <div>Access denied. Please log in.</div>,
}) => {
  const { isAuthenticated, isLoading, hasGroup, isAdmin } = useAuthentik();

  if (isLoading) {
    return <div>Loading authentication...</div>;
  }

  if (!isAuthenticated) {
    return fallback;
  }

  if (requireAdmin && !isAdmin()) {
    return <div>Admin access required.</div>;
  }

  if (requiredGroups.length > 0 && !requiredGroups.some(group => hasGroup(group))) {
    return <div>Insufficient permissions.</div>;
  }

  return <>{children}</>;
};

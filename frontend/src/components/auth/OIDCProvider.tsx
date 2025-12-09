import React from 'react';
import { AuthProvider } from 'react-oidc-context';
import type { AuthProviderProps } from 'react-oidc-context';

const authentikUrl = import.meta.env.VITE_AUTHENTIK_URL || 'http://localhost:9000';
const clientId = import.meta.env.VITE_AUTHENTIK_CLIENT_ID || 'gtin-finder';
const appSlug = import.meta.env.VITE_AUTHENTIK_APP_SLUG || 'gtin-finder';

const oidcConfig: AuthProviderProps = {
  authority: authentikUrl,
  client_id: clientId,
  redirect_uri: window.location.origin,
  scope: 'openid profile email offline_access',
  response_type: 'code',
  automaticSilentRenew: true,
  silent_redirect_uri: `${window.location.origin}/silent-renew.html`,
  post_logout_redirect_uri: window.location.origin,
  // Authentik specific configuration
  metadata: {
    issuer: `${authentikUrl}/application/o/${appSlug}/`,
    authorization_endpoint: `${authentikUrl}/application/o/authorize/`,
    token_endpoint: `${authentikUrl}/application/o/token/`,
    userinfo_endpoint: `${authentikUrl}/application/o/userinfo/`,
    end_session_endpoint: `${authentikUrl}/application/o/${appSlug}/end-session/`,
    jwks_uri: `${authentikUrl}/application/o/${appSlug}/jwks/`,
  },
  // Optional: Custom events for better UX
  onSigninCallback: () => {
    window.history.replaceState({}, document.title, window.location.pathname);
  },
};

export const OIDCProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <AuthProvider {...oidcConfig}>{children}</AuthProvider>;
};

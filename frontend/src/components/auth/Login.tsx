import React from 'react';
import { useAuthentik } from './useAuthentik';
import { Button } from '../common/Button';

export const Login: React.FC = () => {
  const { login, isLoading, error } = useAuthentik();

  const handleLogin = () => {
    login();
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Sign in to GTINFinder
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Use your Authentik account to access the application
          </p>
        </div>
        
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
            Authentication error: {error.message}
          </div>
        )}
        
        <div className="mt-8 space-y-6">
          <Button
            onClick={handleLogin}
            loading={isLoading}
            disabled={isLoading}
            className="w-full"
          >
            {isLoading ? 'Redirecting to Authentik...' : 'Sign in with Authentik'}
          </Button>
          
          <div className="text-center text-sm text-gray-600">
            <p>
              You will be redirected to Authentik for authentication.
            </p>
            <p className="mt-2">
              Don't have an account?{' '}
              <a href="#" className="font-medium text-primary-600 hover:text-primary-500">
                Contact your administrator
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

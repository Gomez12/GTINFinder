import React, { useState, useEffect } from 'react';
import { useAuth } from '../components/auth/AuthProvider';
import { Button } from '../components/common/Button';
import { GTINInput } from '../components/gtin/GTINInput';
import { createGTIN, getGTINs } from '../services/directus';
import type { GTIN } from '../services/directus';
import { validateGTIN } from '../utils/gtinValidator';

export const Dashboard: React.FC = () => {
  const { logoutUser } = useAuth();
  const [gtins, setGTINs] = useState<GTIN[]>([]);
  const [loading, setLoading] = useState(false);
  const [gtinInput, setGtinInput] = useState('');
  const [gtinValidation, setGtinValidation] = useState<any | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Load GTINs on component mount
  useEffect(() => {
    loadGTINs();
  }, []);

  const loadGTINs = async () => {
    try {
      setLoading(true);
      const data = await getGTINs(20); // Load last 20 GTINs
      setGTINs(data);
    } catch (error) {
      console.error('Error loading GTINs:', error);
      setError('Failed to load GTINs');
    } finally {
      setLoading(false);
    }
  };

  const handleGTINChange = (value: string, validation: any) => {
    setGtinInput(value);
    setGtinValidation(validation);
    setError('');
    setSuccess('');
  };

  const handleSubmitGTIN = async () => {
    if (!gtinValidation || !gtinValidation.isValid) {
      setError('Please enter a valid GTIN code');
      return;
    }

    try {
      setSubmitting(true);
      setError('');
      setSuccess('');

      // Create GTIN in Directus
      const newGTIN = await createGTIN(gtinValidation.gtin);
      
      // Add to local state
      setGTINs(prev => [newGTIN, ...prev]);
      
      // Reset form
      setGtinInput('');
      setGtinValidation(null);
      setSuccess(`GTIN ${gtinValidation.gtin} added successfully!`);
      
      // Reload GTINs to get updated list
      await loadGTINs();
    } catch (error) {
      console.error('Error creating GTIN:', error);
      setError(error instanceof Error ? error.message : 'Failed to create GTIN');
    } finally {
      setSubmitting(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'valid':
        return 'text-green-600 bg-green-100';
      case 'invalid':
        return 'text-red-600 bg-red-100';
      case 'duplicate':
        return 'text-yellow-600 bg-yellow-100';
      case 'processing':
        return 'text-blue-600 bg-blue-100';
      case 'completed':
        return 'text-green-600 bg-green-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">GTINFinder</h1>
              <p className="text-gray-600">GTIN Data Enrichment Platform</p>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">
                Welcome, User
              </span>
              <Button variant="secondary" onClick={logoutUser}>
                Logout
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {/* GTIN Input Section */}
          <div className="card mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">
              Add New GTIN
            </h2>
            
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
                {error}
              </div>
            )}
            
            {success && (
              <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded mb-4">
                {success}
              </div>
            )}

            <div className="space-y-4">
              <GTINInput
                value={gtinInput}
                onChange={handleGTINChange}
                disabled={submitting}
              />
              
              <Button
                onClick={handleSubmitGTIN}
                loading={submitting}
                disabled={!gtinValidation?.isValid || submitting}
                className="w-full sm:w-auto"
              >
                {submitting ? 'Adding GTIN...' : 'Add GTIN'}
              </Button>
            </div>
          </div>

          {/* GTINs List */}
          <div className="card">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">
                Recent GTINs
              </h2>
              <Button variant="secondary" onClick={loadGTINs} disabled={loading}>
                {loading ? 'Loading...' : 'Refresh'}
              </Button>
            </div>

            {loading && gtins.length === 0 ? (
              <div className="text-center py-8">
                <div className="loading-spinner w-8 h-8 mx-auto mb-4"></div>
                <p className="text-gray-600">Loading GTINs...</p>
              </div>
            ) : gtins.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-600">No GTINs found. Add your first GTIN above!</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        GTIN Code
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Created
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Updated
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {gtins.map((gtin) => (
                      <tr key={gtin.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {gtin.gtin_code}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(gtin.status)}`}>
                            {gtin.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {formatDate(gtin.created_at)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {formatDate(gtin.updated_at)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
};

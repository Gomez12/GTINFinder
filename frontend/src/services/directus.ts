/**
 * Directus API Service - Simplified Version
 * Handles all communication with Directus backend
 */

// Types for GTIN data
export interface GTIN {
  id: number;
  gtin_code: string;
  status: 'pending' | 'valid' | 'invalid' | 'duplicate' | 'processing' | 'completed';
  created_at: string;
  updated_at: string;
}

export interface GTINRawData {
  id: number;
  gtin_id: number;
  source_name: string;
  raw_data: Record<string, unknown>;
  quality_score: number;
  retrieved_at: string;
}

export interface GTINGoldenRecord {
  id: number;
  gtin_id: number;
  merged_data: Record<string, unknown>;
  confidence_score: number;
  created_at: string;
}

export interface DataSource {
  id: number;
  source_name: string;
  api_endpoint: string;
  rate_limit: number;
  status: 'active' | 'inactive' | 'error';
  priority: number;
  created_at: string;
}

export interface DataQualityScore {
  id: number;
  gtin_id: number;
  source_name: string;
  completeness: number;
  accuracy: number;
  freshness: number;
  created_at: string;
}

// Simple API client for Directus
class DirectusClient {
  private baseURL: string;
  private token: string | null = null;

  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }

  setToken(token: string) {
    this.token = token;
  }

  clearToken() {
    this.token = null;
  }

  private async request(endpoint: string, options: RequestInit = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const headers = {
      'Content-Type': 'application/json',
      ...(this.token && { Authorization: `Bearer ${this.token}` }),
      ...options.headers,
    };

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }

  // Authentication
  async login(email: string, password: string) {
    const data = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    if (data.data?.access_token) {
      this.setToken(data.data.access_token);
      return { success: true };
    }

    return { success: false, error: 'Login failed' };
  }

  async logout() {
    try {
      await this.request('/auth/logout', { method: 'POST' });
    } finally {
      this.clearToken();
    }
    return { success: true };
  }

  async getCurrentUser() {
    try {
      const data = await this.request('/users/me');
      return data.data;
    } catch (error) {
      return null;
    }
  }

  // GTIN operations
  async createGTIN(gtinCode: string): Promise<GTIN> {
    const data = await this.request('/items/gtins', {
      method: 'POST',
      body: JSON.stringify({
        gtin_code: gtinCode,
        status: 'pending',
      }),
    });
    return data.data;
  }

  async getGTINs(limit = 50, offset = 0): Promise<GTIN[]> {
    const data = await this.request(
      `/items/gtins?limit=${limit}&offset=${offset}&sort=-created_at`
    );
    return data.data || [];
  }

  async getGTIN(id: number): Promise<GTIN | null> {
    try {
      const data = await this.request(`/items/gtins/${id}`);
      return data.data;
    } catch (error) {
      return null;
    }
  }

  async updateGTINStatus(id: number, status: GTIN['status']): Promise<GTIN> {
    const data = await this.request(`/items/gtins/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        status,
        updated_at: new Date().toISOString(),
      }),
    });
    return data.data;
  }

  async deleteGTIN(id: number): Promise<void> {
    await this.request(`/items/gtins/${id}`, {
      method: 'DELETE',
    });
  }

  // Raw data operations
  async getGTINRawData(gtinId: number): Promise<GTINRawData[]> {
    const data = await this.request(
      `/items/gtin_raw_data?filter={\"gtin_id\":{\"_eq\":${gtinId}}}&sort=-retrieved_at`
    );
    return data.data || [];
  }

  // Golden record operations
  async getGTINGoldenRecord(gtinId: number): Promise<GTINGoldenRecord | null> {
    try {
      const data = await this.request(
        `/items/gtin_golden_records?filter={\"gtin_id\":{\"_eq\":${gtinId}}}&limit=1`
      );
      return data.data?.[0] || null;
    } catch (error) {
      return null;
    }
  }

  // Data source operations
  async getDataSources(): Promise<DataSource[]> {
    const data = await this.request(
      '/items/data_sources?filter={\"status\":{\"_eq\":\"active\"}}&sort=priority'
    );
    return data.data || [];
  }

  // Quality score operations
  async getGTINQualityScores(gtinId: number): Promise<DataQualityScore[]> {
    const data = await this.request(
      `/items/data_quality_scores?filter={\"gtin_id\":{\"_eq\":${gtinId}}}&sort=-created_at`
    );
    return data.data || [];
  }

  // Utility functions
  async getGTINStats() {
    try {
      const [totalResult, pendingResult, validResult, invalidResult] = await Promise.all([
        this.request('/items/gtins?aggregate[count=*]'),
        this.request('/items/gtins?filter={\"status\":{\"_eq\":\"pending\"}}&aggregate[count=*]'),
        this.request('/items/gtins?filter={\"status\":{\"_eq\":\"valid\"}}&aggregate[count=*]'),
        this.request('/items/gtins?filter={\"status\":{\"_eq\":\"invalid\"}}&aggregate[count=*]'),
      ]);

      return {
        total: totalResult.data?.[0]?.count || 0,
        pending: pendingResult.data?.[0]?.count || 0,
        valid: validResult.data?.[0]?.count || 0,
        invalid: invalidResult.data?.[0]?.count || 0,
      };
    } catch (error) {
      return {
        total: 0,
        pending: 0,
        valid: 0,
        invalid: 0,
      };
    }
  }
}

// Create and export client instance
const directus = new DirectusClient('http://localhost:8055');

// Export client and functions
export const getDirectusInstance = () => directus;

export const authenticate = async (email: string, password: string) => {
  return directus.login(email, password);
};

export const logout = async () => {
  return directus.logout();
};

export const isAuthenticated = () => {
  return !!localStorage.getItem('directus_token');
};

export const createGTIN = (gtinCode: string) => {
  return directus.createGTIN(gtinCode);
};

export const getGTINs = (limit = 50, offset = 0) => {
  return directus.getGTINs(limit, offset);
};

export const getGTIN = (id: number) => {
  return directus.getGTIN(id);
};

export const updateGTINStatus = (id: number, status: GTIN['status']) => {
  return directus.updateGTINStatus(id, status);
};

export const deleteGTIN = (id: number) => {
  return directus.deleteGTIN(id);
};

export const getGTINRawData = (gtinId: number) => {
  return directus.getGTINRawData(gtinId);
};

export const getGTINGoldenRecord = (gtinId: number) => {
  return directus.getGTINGoldenRecord(gtinId);
};

export const getDataSources = () => {
  return directus.getDataSources();
};

export const getGTINQualityScores = (gtinId: number) => {
  return directus.getGTINQualityScores(gtinId);
};

export const getGTINStats = () => {
  return directus.getGTINStats();
};

// Error handling
export const handleDirectusError = (error: unknown): string => {
  if (error instanceof Error) {
    return error.message;
  }
  return 'An unexpected error occurred';
};

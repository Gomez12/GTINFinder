// Common types for GTINFinder application

export interface User {
  id: number;
  email: string;
  first_name?: string;
  last_name?: string;
  role?: string;
}

export interface ApiResponse<T = unknown> {
  data: T;
  error?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total_count: number;
    filter_count: number;
  };
}

export type DirectusError = {
  response?: {
    status: number;
    data: {
      errors: Array<{
        message: string;
        extensions?: Record<string, unknown>;
      }>;
    };
  };
  request?: unknown;
};

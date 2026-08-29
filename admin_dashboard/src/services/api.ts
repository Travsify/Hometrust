import axios from 'axios';

let rawUrl = (import.meta as any).env?.VITE_API_URL || 'http://localhost:5000/api/v1';
if (rawUrl && !rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
  rawUrl = `https://${rawUrl}`;
}
if (rawUrl && !rawUrl.endsWith('/api/v1') && !rawUrl.endsWith('/api/v1/')) {
  rawUrl = `${rawUrl.replace(/\/$/, '')}/api/v1`;
}
const API_BASE_URL = rawUrl;

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach token if present
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('estateverify_admin_token') || 'mock_admin_token';
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const loginAdmin = async (email: string, password: string) => {
  const response = await api.post('/auth/login', { email, password });
  if (response.data.success && response.data.data.token) {
    localStorage.setItem('estateverify_admin_token', response.data.data.token);
    localStorage.setItem('estateverify_admin_user', JSON.stringify(response.data.data.user));
  }
  return response.data;
};

export const getDashboardMetrics = async () => {
  const response = await api.get('/admin/metrics');
  return response.data.data;
};

export const getVerificationRequests = async (status?: string) => {
  const url = status ? `/verifications/all?status=${status}` : '/verifications/all';
  const response = await api.get(url);
  return response.data.data;
};

export const updateVerificationStatus = async (id: string, data: any) => {
  const response = await api.patch(`/verifications/${id}/status`, data);
  return response.data.data;
};

export const getDevelopers = async () => {
  const response = await api.get('/developers');
  return response.data.data;
};

export const verifyDeveloper = async (id: string, status: string, categories: string[]) => {
  const response = await api.patch(`/developers/${id}/verify`, { status, categories });
  return response.data.data;
};

export const getProperties = async () => {
  const response = await api.get('/properties');
  return response.data.data;
};

export const getProjects = async () => {
  const response = await api.get('/projects');
  return response.data.data;
};

export const updateMilestone = async (milestoneId: string, data: any) => {
  const response = await api.patch(`/projects/milestones/${milestoneId}`, data);
  return response.data.data;
};

export const getLegalRequests = async () => {
  const response = await api.get('/legal/all');
  return response.data.data;
};

export const updateLegalRequest = async (id: string, data: any) => {
  const response = await api.patch(`/legal/${id}/status`, data);
  return response.data.data;
};

export const getAuditLogs = async () => {
  const response = await api.get('/admin/audit-logs');
  return response.data.data;
};

export const getPlatformFees = async () => {
  const response = await api.get('/admin/platform-fees');
  return response.data.data;
};

export const updatePlatformFee = async (id: string, amount: number, isActive: boolean) => {
  const response = await api.patch(`/admin/platform-fees/${id}`, { amount, isActive });
  return response.data.data;
};

import axios from 'axios';

const getApiBaseUrl = () => {
  const envUrl = (import.meta as any).env?.VITE_API_URL;
  if (envUrl && envUrl.trim() !== '') {
    let u = envUrl.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = `https://${u}`;
    }
    return u.endsWith('/api/v1') ? u : `${u.replace(/\/$/, '')}/api/v1`;
  }

  // In browser runtime, if on a domain like https://hometrust.onrender.com, use relative /api/v1
  if (typeof window !== 'undefined' && window.location) {
    if (window.location.hostname === 'localhost' && window.location.port === '3000') {
      return 'http://localhost:5000/api/v1';
    }
    return `${window.location.origin}/api/v1`;
  }

  return 'http://localhost:5000/api/v1';
};

const API_BASE_URL = getApiBaseUrl();

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach token if present
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('hometrust_admin_token') || localStorage.getItem('estateverify_admin_token') || 'mock_admin_token';
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const loginAdmin = async (email: string, password: string) => {
  const response = await api.post('/auth/login', { email, password });
  if (response.data.success && response.data.data.token) {
    localStorage.setItem('hometrust_admin_token', response.data.data.token);
    localStorage.setItem('hometrust_admin_user', JSON.stringify(response.data.data.user));
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

export const createPlatformFee = async (data: any) => {
  const response = await api.post('/admin/platform-fees', data);
  return response.data.data;
};

export const updatePlatformFee = async (id: string, data: any) => {
  const response = await api.patch(`/admin/platform-fees/${id}`, data);
  return response.data.data;
};

export const getApiKeys = async () => {
  const response = await api.get('/admin/api-keys');
  return response.data.data;
};

export const addApiKey = async (data: any) => {
  const response = await api.post('/admin/api-keys', data);
  return response.data.data;
};

export const updateApiKey = async (id: string, data: any) => {
  const response = await api.patch(`/admin/api-keys/${id}`, data);
  return response.data.data;
};

export const deleteApiKey = async (id: string) => {
  const response = await api.delete(`/admin/api-keys/${id}`);
  return response.data.data;
};

export const testApiKey = async (id: string) => {
  const response = await api.post(`/admin/api-keys/${id}/test`);
  return response.data.data;
};

export const getUsers = async (search?: string, role?: string) => {
  let url = '/admin/users?';
  if (search) url += `search=${search}&`;
  if (role) url += `role=${role}&`;
  const response = await api.get(url);
  return response.data.data;
};

export const updateUserStatus = async (id: string, isActive: boolean) => {
  const response = await api.patch(`/admin/users/${id}/status`, { isActive });
  return response.data.data;
};

export const updateUserRole = async (id: string, role: string) => {
  const response = await api.patch(`/admin/users/${id}/role`, { role });
  return response.data.data;
};

export const getVirtualAccounts = async () => {
  const response = await api.get('/banking/admin/accounts');
  return response.data.data;
};

export const getWithdrawals = async () => {
  const response = await api.get('/banking/admin/withdrawals');
  return response.data.data;
};

export const getKycVerifications = async () => {
  const response = await api.get('/banking/admin/kyc-verifications');
  return response.data.data;
};

export const resolveAccount = async (bankCode: string, accountNumber: string) => {
  const response = await api.post('/banking/resolve-account', { bankCode, accountNumber });
  return response.data.data;
};

export const getMaterialsIndex = async (category?: string, state?: string) => {
  let url = '/materials?';
  if (category) url += `category=${category}&`;
  if (state) url += `state=${state}&`;
  const response = await api.get(url);
  return response.data.data;
};

export const getAdminMilestones = async () => {
  const response = await api.get('/admin/milestones');
  return response.data.data;
};

export const adminDisburseMilestone = async (id: string, action: 'DISBURSE' | 'DISPUTE' | 'REMEDIATION_REQUIRED', notes?: string) => {
  const response = await api.post(`/admin/milestones/${id}/disburse`, { action, notes });
  return response.data.data;
};

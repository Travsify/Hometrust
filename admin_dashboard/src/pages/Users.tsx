import React, { useState, useEffect } from 'react';
import { Search, Shield, UserCheck, UserX, Download, Filter, Mail, Phone, Calendar } from 'lucide-react';
import { getUsers, updateUserStatus, updateUserRole } from '../services/api';
import { exportToCsv } from '../utils/exportCsv';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const fetchUsersList = async () => {
    setLoading(true);
    try {
      const data = await getUsers(searchTerm, roleFilter);
      setUsers(data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsersList();
  }, [searchTerm, roleFilter]);

  const handleToggleStatus = async (id: string, currentStatus: boolean) => {
    setUpdatingId(id);
    try {
      await updateUserStatus(id, !currentStatus);
      await fetchUsersList();
    } catch (e) {
      alert('Failed to update user status');
    } finally {
      setUpdatingId(null);
    }
  };

  const handleChangeRole = async (id: string, newRole: string) => {
    setUpdatingId(id);
    try {
      await updateUserRole(id, newRole);
      await fetchUsersList();
    } catch (e) {
      alert('Failed to update user role');
    } finally {
      setUpdatingId(null);
    }
  };

  const handleExport = () => {
    const formatted = users.map((u) => ({
      ID: u.id,
      FullName: `${u.firstName} ${u.lastName}`,
      Email: u.email,
      Phone: u.phone || 'N/A',
      Role: u.role,
      Status: u.isActive ? 'Active' : 'Suspended',
      EmailVerified: u.isEmailVerified ? 'Yes' : 'No',
      DeveloperCompany: u.developer?.companyName || 'N/A',
      CreatedAt: new Date(u.createdAt).toLocaleDateString(),
    }));
    exportToCsv('Hometrust_Users_Registry', formatted);
  };

  const roles = [
    'BUYER',
    'DEVELOPER',
    'LEGAL_MANAGER',
    'VERIFICATION_MANAGER',
    'FINANCE_MANAGER',
    'SUPPORT_AGENT',
    'ADMIN',
    'SUPER_ADMIN',
  ];

  return (
    <div className="space-y-6">
      {/* Search & Actions Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-72">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div className="relative">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="bg-slate-950 border border-slate-800 text-slate-300 text-xs rounded-xl py-2.5 px-3 focus:outline-none focus:border-emerald-500"
            >
              <option value="">All Roles</option>
              {roles.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
        </div>

        <button
          onClick={handleExport}
          className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30 rounded-xl text-xs font-semibold transition-colors shrink-0"
        >
          <Download className="w-4 h-4" />
          <span>Export Users CSV</span>
        </button>
      </div>

      {/* Users Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
              <tr>
                <th className="px-6 py-4">User Details</th>
                <th className="px-6 py-4">Contact</th>
                <th className="px-6 py-4">Role Assignment</th>
                <th className="px-6 py-4">Account Status</th>
                <th className="px-6 py-4">Joined Date</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {loading ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-400">
                    Loading users...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-500">
                    No users matching criteria.
                  </td>
                </tr>
              ) : (
                users.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center font-bold">
                          {u.firstName?.[0] || 'U'}
                        </div>
                        <div>
                          <div className="font-bold text-white">
                            {u.firstName} {u.lastName}
                          </div>
                          <div className="text-[11px] text-slate-400">{u.email}</div>
                          {u.developer && (
                            <div className="text-[10px] text-emerald-400 font-semibold mt-0.5">
                              🏢 {u.developer.companyName}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-slate-300">{u.phone || 'No phone'}</div>
                      <div className="text-[10px] text-slate-500">
                        {u.isEmailVerified ? '✓ Email Verified' : 'Unverified'}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <select
                        value={u.role}
                        onChange={(e) => handleChangeRole(u.id, e.target.value)}
                        disabled={updatingId === u.id}
                        className="bg-slate-950 border border-slate-800 text-emerald-400 text-xs font-semibold rounded-lg px-2.5 py-1 focus:outline-none focus:border-emerald-500"
                      >
                        {roles.map((r) => (
                          <option key={r} value={r}>
                            {r}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-[10px] ${
                          u.isActive
                            ? 'bg-emerald-950/80 text-emerald-400 border border-emerald-800/60'
                            : 'bg-rose-950/80 text-rose-400 border border-rose-800/60'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            u.isActive ? 'bg-emerald-500' : 'bg-rose-500'
                          }`}
                        ></span>
                        {u.isActive ? 'ACTIVE' : 'SUSPENDED'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-400">
                      {new Date(u.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => handleToggleStatus(u.id, u.isActive)}
                        disabled={updatingId === u.id}
                        className={`px-3 py-1.5 rounded-lg font-semibold text-xs transition-colors ${
                          u.isActive
                            ? 'bg-rose-600/20 hover:bg-rose-600/30 text-rose-400 border border-rose-500/30'
                            : 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30'
                        }`}
                      >
                        {u.isActive ? 'Suspend' : 'Activate'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

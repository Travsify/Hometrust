import React, { useState, useEffect } from 'react';
import {
  Search,
  ShieldCheck,
  ShieldAlert,
  UserCheck,
  UserX,
  Download,
  Building2,
  CreditCard,
  AlertTriangle,
  RotateCcw,
  CheckCircle2,
  RefreshCw,
  Eye,
} from 'lucide-react';
import { getVerifiedUsers, revokeUserKyc, verifyUserKyc } from '../services/api';
import { exportToCsv } from '../utils/exportCsv';

export const VerifiedUsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [actionUserId, setActionUserId] = useState<string | null>(null);
  const [showRevokeModal, setShowRevokeModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [revokeReason, setRevokeReason] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [viewUserModal, setViewUserModal] = useState<any>(null);

  const fetchList = async () => {
    setLoading(true);
    try {
      const data = await getVerifiedUsers(searchTerm);
      setUsers(data || []);
    } catch (e) {
      console.error('Failed to load verified users:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchList();
  }, [searchTerm]);

  const handleOpenRevoke = (u: any) => {
    setSelectedUser(u);
    setRevokeReason('');
    setShowRevokeModal(true);
  };

  const handleConfirmRevoke = async () => {
    if (!selectedUser) return;
    setSubmitting(true);
    try {
      await revokeUserKyc(selectedUser.id, revokeReason.trim() || 'Administrative Review & Profile Update');
      setShowRevokeModal(false);
      setSelectedUser(null);
      await fetchList();
      alert(`KYC verification revoked for ${selectedUser.firstName} ${selectedUser.lastName}. The user will be required to re-verify in the app.`);
    } catch (e: any) {
      alert(`Failed to revoke verification: ${e.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  const handleManualVerify = async (userId: string, userName: string) => {
    if (!confirm(`Manually approve & restore KYC verification badge for ${userName}?`)) return;
    setActionUserId(userId);
    try {
      await verifyUserKyc(userId);
      await fetchList();
      alert(`KYC verification approved for ${userName}.`);
    } catch (e: any) {
      alert(`Failed to verify user: ${e.message}`);
    } finally {
      setActionUserId(null);
    }
  };

  const handleExport = () => {
    const formatted = users.map((u) => ({
      ID: u.id,
      FullName: `${u.firstName} ${u.lastName}`,
      Email: u.email,
      Phone: u.phone || 'N/A',
      Role: u.role,
      AccountType: u.developer ? 'CORPORATE' : 'INDIVIDUAL',
      CorporateName: u.developer?.companyName || 'N/A',
      BankAccountNumber: u.virtualAccount?.accountNumber || 'N/A',
      BankName: u.virtualAccount?.bankName || 'N/A',
      WalletBalance: u.virtualAccount?.balance ? `₦${u.virtualAccount.balance.toLocaleString()}` : '₦0',
      Status: u.isActive ? 'Active' : 'Suspended',
      VerifiedStatus: 'VERIFIED',
      RegisteredDate: new Date(u.createdAt).toLocaleDateString(),
    }));
    exportToCsv('Hometrust_Verified_Users_Registry', formatted);
  };

  const totalVerified = users.length;
  const buyersCount = users.filter((u) => u.role === 'BUYER').length;
  const developersCount = users.filter((u) => u.developer || u.role === 'DEVELOPER').length;
  const totalBalance = users.reduce((acc, u) => acc + (u.virtualAccount?.balance || 0), 0);

  return (
    <div className="space-y-6 font-['Plus_Jakarta_Sans',sans-serif]">
      {/* Top Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Verified Users</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-white mt-3">{totalVerified}</p>
          <p className="text-[11px] text-emerald-400 font-semibold mt-1">✓ 100% Identity Checked</p>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Verified Buyers</span>
            <div className="w-8 h-8 rounded-lg bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <UserCheck className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-white mt-3">{buyersCount}</p>
          <p className="text-[11px] text-slate-400 mt-1">NIN / BVN Validated</p>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Corporate / Developers</span>
            <div className="w-8 h-8 rounded-lg bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <Building2 className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-white mt-3">{developersCount}</p>
          <p className="text-[11px] text-amber-400 mt-1">CAC RC & Director Audited</p>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Escrow Funds</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <CreditCard className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-black text-emerald-400 mt-3">₦{totalBalance.toLocaleString()}</p>
          <p className="text-[11px] text-slate-400 mt-1">Held in Dedicated NUBANs</p>
        </div>
      </div>

      {/* Search & Actions Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-80">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, email, phone, account..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <button
            onClick={fetchList}
            className="p-2.5 bg-slate-950 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded-xl text-xs transition-colors"
            title="Refresh list"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        <button
          onClick={handleExport}
          className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30 rounded-xl text-xs font-semibold transition-colors shrink-0"
        >
          <Download className="w-4 h-4" />
          <span>Export Verified Users CSV</span>
        </button>
      </div>

      {/* Verified Users Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
              <tr>
                <th className="px-6 py-4">User & Identity</th>
                <th className="px-6 py-4">Role & Account Type</th>
                <th className="px-6 py-4">Dedicated Bank Account</th>
                <th className="px-6 py-4">Escrow Balance</th>
                <th className="px-6 py-4">Verification Status</th>
                <th className="px-6 py-4 text-right">Governance Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {loading ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-400">
                    Loading verified users registry...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-500">
                    No verified users found matching search.
                  </td>
                </tr>
              ) : (
                users.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center font-bold text-sm">
                          {u.firstName?.[0] || 'U'}
                        </div>
                        <div>
                          <div className="font-bold text-white flex items-center gap-1.5">
                            <span>{u.name || `${u.firstName} ${u.lastName}`}</span>
                            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                          </div>
                          <div className="text-[11px] text-slate-400">{u.email}</div>
                          <div className="text-[10px] text-slate-500">{u.phone || 'No phone'}</div>
                        </div>
                      </div>
                    </td>

                    <td className="px-6 py-4">
                      <div className="space-y-1">
                        <span className="inline-block px-2.5 py-0.5 rounded-md bg-slate-800 text-slate-300 font-semibold text-[10px]">
                          {u.role}
                        </span>
                        {u.developer && (
                          <div className="text-[11px] text-amber-400 font-semibold flex items-center gap-1">
                            <Building2 className="w-3 h-3" />
                            <span>{u.developer.companyName}</span>
                          </div>
                        )}
                      </div>
                    </td>

                    <td className="px-6 py-4">
                      {u.virtualAccount ? (
                        <div>
                          <div className="font-mono text-emerald-400 font-bold text-xs tracking-wider">
                            {u.virtualAccount.accountNumber}
                          </div>
                          <div className="text-[10px] text-slate-400">{u.virtualAccount.bankName}</div>
                          <div className="text-[10px] text-slate-500 truncate max-w-[180px]">
                            {u.virtualAccount.accountName}
                          </div>
                        </div>
                      ) : (
                        <span className="text-slate-500 italic text-[11px]">No account generated</span>
                      )}
                    </td>

                    <td className="px-6 py-4">
                      <div className="font-bold text-white text-xs">
                        ₦{(u.virtualAccount?.balance || 0).toLocaleString()}
                      </div>
                      <div className="text-[10px] text-emerald-400 font-semibold">Available for withdrawal</div>
                    </td>

                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-bold text-[10px] bg-emerald-950 text-emerald-400 border border-emerald-800/80 shadow-sm">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                        VERIFIED 🛡️
                      </span>
                    </td>

                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => setViewUserModal(u)}
                          className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-xs font-semibold transition-colors"
                          title="View user details"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>

                        <button
                          onClick={() => handleOpenRevoke(u)}
                          disabled={actionUserId === u.id}
                          className="flex items-center gap-1.5 px-3 py-1.5 bg-rose-600/20 hover:bg-rose-600/30 text-rose-400 border border-rose-500/30 rounded-lg text-xs font-semibold transition-colors"
                          title="Revoke KYC status and require user to re-verify"
                        >
                          <ShieldAlert className="w-3.5 h-3.5" />
                          <span>Revoke KYC</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Revocation Confirmation Modal */}
      {showRevokeModal && selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 text-rose-400">
              <div className="p-3 bg-rose-500/10 rounded-xl border border-rose-500/20">
                <AlertTriangle className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-bold text-white text-base">Revoke User Verification?</h3>
                <p className="text-xs text-slate-400">Reset identity verification for {selectedUser.firstName} {selectedUser.lastName}</p>
              </div>
            </div>

            <div className="bg-slate-950 p-3.5 rounded-xl border border-slate-800/80 text-xs text-slate-300 space-y-2">
              <p className="font-semibold text-rose-300">⚠️ Consequence of Revocation:</p>
              <ul className="list-disc pl-4 space-y-1 text-[11px] text-slate-400">
                <li>User's KYC badge will revert to <strong className="text-white">UNVERIFIED</strong> in the mobile app.</li>
                <li>The user will be prompted to re-submit valid identification (NIN/BVN).</li>
                <li>An in-app audit notification will be sent to the user.</li>
              </ul>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                Revocation Reason (Optional note for user)
              </label>
              <textarea
                value={revokeReason}
                onChange={(e) => setRevokeReason(e.target.value)}
                placeholder="e.g. Identity document expired / Mismatch detected during periodic audit..."
                rows={3}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-rose-500"
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setShowRevokeModal(false)}
                disabled={submitting}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmRevoke}
                disabled={submitting}
                className="px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold rounded-xl shadow-lg shadow-rose-900/30 transition-colors flex items-center gap-1.5"
              >
                {submitting ? 'Revoking...' : 'Confirm Revoke KYC'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* View User Details Modal */}
      {viewUserModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center font-bold">
                  {viewUserModal.firstName?.[0] || 'U'}
                </div>
                <div>
                  <h3 className="font-bold text-white text-base">{viewUserModal.firstName} {viewUserModal.lastName}</h3>
                  <p className="text-xs text-emerald-400 font-semibold">VERIFIED IDENTITY PROFILE</p>
                </div>
              </div>
              <button
                onClick={() => setViewUserModal(null)}
                className="text-slate-400 hover:text-white text-lg font-bold p-1"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">Email Address</span>
                  <span className="text-white font-medium">{viewUserModal.email}</span>
                </div>
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800">
                  <span className="text-slate-400 block text-[10px] uppercase font-semibold">Phone Number</span>
                  <span className="text-white font-medium">{viewUserModal.phone || 'N/A'}</span>
                </div>
              </div>

              <div className="bg-slate-950 p-3.5 rounded-xl border border-slate-800 space-y-2">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Dedicated NUBAN Escrow Bank Account</span>
                {viewUserModal.virtualAccount ? (
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-mono text-emerald-400 font-bold text-sm tracking-wider">{viewUserModal.virtualAccount.accountNumber}</p>
                      <p className="text-slate-300 text-[11px]">{viewUserModal.virtualAccount.bankName} • {viewUserModal.virtualAccount.accountName}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-slate-400 text-[10px]">Escrow Balance</p>
                      <p className="text-emerald-400 font-bold text-sm">₦{(viewUserModal.virtualAccount.balance || 0).toLocaleString()}</p>
                    </div>
                  </div>
                ) : (
                  <p className="text-slate-500 italic">No virtual account linked</p>
                )}
              </div>

              {viewUserModal.developer && (
                <div className="bg-amber-950/40 p-3.5 rounded-xl border border-amber-800/40">
                  <span className="text-amber-400 block text-[10px] uppercase font-semibold">Corporate Developer Profile</span>
                  <p className="text-white font-bold text-sm mt-0.5">{viewUserModal.developer.companyName}</p>
                  <p className="text-slate-300 text-[11px]">Verification Status: {viewUserModal.developer.verificationStatus || 'VERIFIED'}</p>
                </div>
              )}
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                onClick={() => setViewUserModal(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-xl transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

import React, { useState, useEffect } from 'react';
import { Landmark, ArrowUpRight, Search, Download, ShieldCheck, UserCheck, RefreshCw, Wallet, Building2, User } from 'lucide-react';
import { getVirtualAccounts, getWithdrawals, getKycVerifications } from '../services/api';
import { exportToCsv } from '../utils/exportCsv';

export const BankingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'accounts' | 'withdrawals' | 'kyc'>('accounts');
  const [accounts, setAccounts] = useState<any[]>([]);
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [kycRecords, setKycRecords] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  const fetchData = async () => {
    setLoading(true);
    try {
      const [accs, withs, kycs] = await Promise.all([
        getVirtualAccounts(),
        getWithdrawals(),
        getKycVerifications(),
      ]);
      setAccounts(accs || []);
      setWithdrawals(withs || []);
      setKycRecords(kycs || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const totalFundedVolume = accounts.reduce((sum, a) => sum + (a.balance || 0), 0);
  const totalPayoutVolume = withdrawals.reduce((sum, w) => sum + (w.amount || 0), 0);
  const verifiedKycCount = kycRecords.filter((k) => k.status === 'VERIFIED').length;

  const filteredAccounts = accounts.filter(
    (a) =>
      !searchTerm ||
      a.accountName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.accountNumber.includes(searchTerm) ||
      a.bankName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredKyc = kycRecords.filter(
    (k) =>
      !searchTerm ||
      (k.user?.firstName && k.user.firstName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.user?.lastName && k.user.lastName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.user?.email && k.user.email.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.developer?.companyName && k.developer.companyName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.companyName && k.companyName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.cacNumber && k.cacNumber.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (k.nin && k.nin.includes(searchTerm)) ||
      (k.bvn && k.bvn.includes(searchTerm))
  );

  const handleExportAccounts = () => {
    const formatted = accounts.map((a) => ({
      AccountName: a.accountName,
      AccountNumber: a.accountNumber,
      BankName: a.bankName,
      AccountType: a.accountType,
      Balance_NGN: a.balance,
      Status: a.status,
      Entity: a.accountType === 'CORPORATE' ? a.developer?.companyName : `${a.user?.firstName} ${a.user?.lastName}`,
      Email: a.accountType === 'CORPORATE' ? a.developer?.email : a.user?.email,
      CreatedAt: new Date(a.createdAt).toLocaleDateString(),
    }));
    exportToCsv('Hometrust_Dedicated_Virtual_Accounts', formatted);
  };

  const handleExportWithdrawals = () => {
    const formatted = withdrawals.map((w) => ({
      Reference: w.reference,
      RecipientName: w.accountName,
      DestinationBank: w.bankName,
      AccountNumber: w.accountNumber,
      GrossAmount_NGN: w.amount,
      Fee_NGN: w.fee,
      NetAmount_NGN: w.netAmount,
      Status: w.status,
      DeveloperCompany: w.developer?.companyName || 'N/A',
      Date: new Date(w.createdAt).toLocaleDateString(),
    }));
    exportToCsv('Hometrust_Developer_Withdrawals', formatted);
  };

  const handleExportKyc = () => {
    const formatted = kycRecords.map((k) => ({
      EntityName: k.developer?.companyName || (k.user ? `${k.user.firstName} ${k.user.lastName}` : (k.companyName || 'N/A')),
      Email: k.developer?.email || k.user?.email || 'N/A',
      Role: k.kycType === 'CORPORATE_KYB' ? 'DEVELOPER' : (k.user?.role || 'BUYER'),
      KYC_Type: k.kycType,
      CAC_or_NIN: k.cacNumber || k.nin || 'N/A',
      BVN: k.bvn || 'N/A',
      Status: k.status,
      VerifiedAt: k.verifiedAt ? new Date(k.verifiedAt).toLocaleString() : 'N/A',
      Provider: 'Prembly / Identitypass',
    }));
    exportToCsv('Hometrust_Prembly_KYC_Verifications', formatted);
  };

  return (
    <div className="space-y-6">
      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Active Dedicated Accounts</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <Landmark className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-white">{accounts.length}</div>
          <div className="text-[11px] text-slate-400">KYC/KYB Dedicated NUBAN Accounts</div>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Prembly KYC Verified Users</span>
            <div className="w-8 h-8 rounded-lg bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <UserCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-blue-400">{verifiedKycCount}</div>
          <div className="text-[11px] text-slate-400">NIN & BVN verified via Prembly</div>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Escrow & Account Balances</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-emerald-400">₦{totalFundedVolume.toLocaleString()}</div>
          <div className="text-[11px] text-slate-400">Available funded bank balances</div>
        </div>
      </div>

      {/* Navigation & Actions Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900 border border-slate-800">
        <div className="flex items-center gap-2 bg-slate-950 p-1 rounded-xl border border-slate-800">
          <button
            onClick={() => setActiveTab('accounts')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'accounts' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            <Landmark className="w-4 h-4" />
            <span>Dedicated Bank Accounts ({accounts.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('kyc')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'kyc' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            <span>Prembly KYC Audits ({kycRecords.length})</span>
          </button>

          <button
            onClick={() => setActiveTab('withdrawals')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'withdrawals' ? 'bg-emerald-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
            }`}
          >
            <ArrowUpRight className="w-4 h-4" />
            <span>Developer Withdrawals ({withdrawals.length})</span>
          </button>
        </div>

        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-64">
            <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-500" />
            <input
              type="text"
              placeholder="Search records..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2 pl-10 pr-4 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <button
            onClick={
              activeTab === 'accounts'
                ? handleExportAccounts
                : activeTab === 'kyc'
                ? handleExportKyc
                : handleExportWithdrawals
            }
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30 rounded-xl text-xs font-semibold transition-colors shrink-0"
          >
            <Download className="w-4 h-4" />
            <span>Export CSV</span>
          </button>

          <button
            onClick={fetchData}
            className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs transition-colors shrink-0"
            title="Refresh"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* TAB 1: DEDICATED VIRTUAL ACCOUNTS TABLE */}
      {activeTab === 'accounts' && (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
                <tr>
                  <th className="px-6 py-4">Account Details</th>
                  <th className="px-6 py-4">Account Number / Bank</th>
                  <th className="px-6 py-4">Account Type</th>
                  <th className="px-6 py-4">Balance</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Created Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="text-center py-12 text-slate-400">
                      Loading virtual bank accounts...
                    </td>
                  </tr>
                ) : filteredAccounts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="text-center py-12 text-slate-500">
                      No virtual bank accounts found.
                    </td>
                  </tr>
                ) : (
                  filteredAccounts.map((a) => (
                    <tr key={a.id} className="hover:bg-slate-800/40 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-bold text-white text-sm">{a.accountName}</div>
                        <div className="text-[11px] text-slate-400">
                          {a.accountType === 'CORPORATE' ? a.developer?.companyName : `${a.user?.firstName} ${a.user?.lastName}`} • {a.user?.email || a.developer?.email}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-mono text-slate-200 font-bold text-sm tracking-wider">{a.accountNumber}</div>
                        <div className="text-[11px] text-slate-400">{a.bankName}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-800 text-slate-300">
                          {a.accountType === 'CORPORATE' ? <Building2 className="w-3 h-3 text-amber-400" /> : <User className="w-3 h-3 text-blue-400" />}
                          {a.accountType}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-bold text-emerald-400 text-sm">
                        ₦{(a.balance || 0).toLocaleString()}
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                          {a.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-slate-400">
                        {new Date(a.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 2: PREMBLY KYC & IDENTITY VERIFICATIONS */}
      {activeTab === 'kyc' && (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
                <tr>
                  <th className="px-6 py-4">Customer Name & Role</th>
                  <th className="px-6 py-4">KYC Type</th>
                  <th className="px-6 py-4">NIN / National ID</th>
                  <th className="px-6 py-4">BVN</th>
                  <th className="px-6 py-4">Prembly Status</th>
                  <th className="px-6 py-4">Verified Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="text-center py-12 text-slate-400">
                      Loading Prembly KYC records...
                    </td>
                  </tr>
                ) : filteredKyc.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="text-center py-12 text-slate-500">
                      No KYC verifications recorded yet.
                    </td>
                  </tr>
                ) : (
                  filteredKyc.map((k) => {
                    const isCorporate = k.kycType === 'CORPORATE_KYB';
                    const entityName = k.developer?.companyName || (k.user ? `${k.user.firstName} ${k.user.lastName}` : (k.companyName || 'Corporate Entity'));
                    const email = k.developer?.email || k.user?.email || 'N/A';
                    const phone = k.developer?.phone || k.user?.phone || 'N/A';
                    return (
                      <tr key={k.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="px-6 py-4">
                          <div className="font-bold text-white text-sm">
                            {entityName}
                          </div>
                          <div className="text-[11px] text-slate-400">{email} • {phone}</div>
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${isCorporate ? 'bg-amber-950 text-amber-300 border border-amber-800' : 'bg-slate-800 text-slate-300'}`}>
                            {isCorporate ? '🏢 CORPORATE KYB' : '👤 INDIVIDUAL KYC'}
                          </span>
                        </td>
                        <td className="px-6 py-4 font-mono font-bold text-slate-200">
                          {isCorporate ? (k.cacNumber || k.developer?.cacNumber || 'RC Verified') : (k.nin ? `${k.nin.substring(0, 3)}•••••${k.nin.substring(k.nin.length - 3)}` : 'N/A')}
                        </td>
                        <td className="px-6 py-4 font-mono font-bold text-slate-200">
                          {isCorporate ? (k.tinNumber || 'TIN Verified') : (k.bvn ? `${k.bvn.substring(0, 3)}•••••${k.bvn.substring(k.bvn.length - 3)}` : 'N/A')}
                        </td>
                        <td className="px-6 py-4">
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                            <ShieldCheck className="w-3 h-3" />
                            {k.status} (Prembly Verified)
                          </span>
                        </td>
                        <td className="px-6 py-4 text-slate-400">
                          {k.verifiedAt ? new Date(k.verifiedAt).toLocaleString() : new Date(k.createdAt).toLocaleString()}
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TAB 3: DEVELOPER WITHDRAWALS & PAYOUTS */}
      {activeTab === 'withdrawals' && (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
                <tr>
                  <th className="px-6 py-4">Transfer Reference</th>
                  <th className="px-6 py-4">Recipient Account Name</th>
                  <th className="px-6 py-4">Destination Bank & NUBAN</th>
                  <th className="px-6 py-4">Gross Amount</th>
                  <th className="px-6 py-4">Net Payout</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4">Timestamp</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60">
                {loading ? (
                  <tr>
                    <td colSpan={7} className="text-center py-12 text-slate-400">
                      Loading withdrawal records...
                    </td>
                  </tr>
                ) : withdrawals.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="text-center py-12 text-slate-500">
                      No withdrawal records found.
                    </td>
                  </tr>
                ) : (
                  withdrawals.map((w) => (
                    <tr key={w.id} className="hover:bg-slate-800/40 transition-colors">
                      <td className="px-6 py-4 font-mono font-bold text-emerald-400">
                        {w.reference}
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-bold text-white">{w.accountName}</div>
                        {w.developer && <div className="text-[11px] text-slate-400">{w.developer.companyName}</div>}
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-mono text-slate-300">{w.accountNumber}</div>
                        <div className="text-[11px] text-slate-400">{w.bankName}</div>
                      </td>
                      <td className="px-6 py-4 font-bold text-white">
                        ₦{w.amount.toLocaleString()}
                      </td>
                      <td className="px-6 py-4 font-extrabold text-emerald-400">
                        ₦{w.netAmount.toLocaleString()}
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                          {w.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-slate-400">
                        {new Date(w.createdAt).toLocaleString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

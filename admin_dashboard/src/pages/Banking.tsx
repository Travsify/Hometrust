import React, { useState, useEffect } from 'react';
import { Landmark, ArrowUpRight, ArrowDownLeft, Search, Download, ShieldCheck, CheckCircle2, Building2, User, RefreshCw, Wallet } from 'lucide-react';
import { getVirtualAccounts, getWithdrawals } from '../services/api';
import { exportToCsv } from '../utils/exportCsv';

export const BankingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'accounts' | 'withdrawals'>('accounts');
  const [accounts, setAccounts] = useState<any[]>([]);
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  const fetchData = async () => {
    setLoading(true);
    try {
      const [accs, withs] = await Promise.all([
        getVirtualAccounts(),
        getWithdrawals(),
      ]);
      setAccounts(accs || []);
      setWithdrawals(withs || []);
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

  const filteredAccounts = accounts.filter(
    (a) =>
      !searchTerm ||
      a.accountName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      a.accountNumber.includes(searchTerm) ||
      a.bankName.toLowerCase().includes(searchTerm.toLowerCase())
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
    exportToCsv('EstateVerify_Dedicated_Virtual_Accounts', formatted);
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
    exportToCsv('EstateVerify_Developer_Withdrawals', formatted);
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
            <span className="text-xs font-semibold">Escrow & Account Balances</span>
            <div className="w-8 h-8 rounded-lg bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <Wallet className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-emerald-400">₦{totalFundedVolume.toLocaleString()}</div>
          <div className="text-[11px] text-slate-400">Available funded bank balances</div>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Total Disbursed Payouts</span>
            <div className="w-8 h-8 rounded-lg bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <ArrowUpRight className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-white">₦{totalPayoutVolume.toLocaleString()}</div>
          <div className="text-[11px] text-slate-400">Developer commercial bank withdrawals</div>
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
              placeholder="Search account number or name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2 pl-10 pr-4 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <button
            onClick={activeTab === 'accounts' ? handleExportAccounts : handleExportWithdrawals}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-500/30 rounded-xl text-xs font-semibold transition-colors shrink-0"
          >
            <Download className="w-4 h-4" />
            <span>Export CSV</span>
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
                      No dedicated virtual accounts found matching criteria.
                    </td>
                  </tr>
                ) : (
                  filteredAccounts.map((a) => (
                    <tr key={a.id} className="hover:bg-slate-800/40 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-bold text-white text-sm">{a.accountName}</div>
                        <div className="text-[11px] text-slate-400">
                          {a.accountType === 'CORPORATE' ? a.developer?.email : a.user?.email}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="font-mono text-base font-extrabold text-emerald-400 tracking-wider">
                          {a.accountNumber}
                        </div>
                        <div className="text-[11px] text-slate-400">{a.bankName}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                            a.accountType === 'CORPORATE'
                              ? 'bg-purple-950 text-purple-300 border border-purple-800'
                              : 'bg-blue-950 text-blue-300 border border-blue-800'
                          }`}
                        >
                          {a.accountType === 'CORPORATE' ? <Building2 className="w-3 h-3" /> : <User className="w-3 h-3" />}
                          {a.accountType === 'CORPORATE' ? 'BUSINESS (KYB)' : 'INDIVIDUAL (KYC)'}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-bold text-white text-sm">
                        ₦{(a.balance || 0).toLocaleString()}
                      </td>
                      <td className="px-6 py-4">
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
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

      {/* TAB 2: DEVELOPER WITHDRAWALS & PAYOUTS */}
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

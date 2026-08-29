import React from 'react';
import {
  ShieldCheck,
  Building2,
  CreditCard,
  CheckCircle2,
  TrendingUp,
  Clock,
  ArrowUpRight,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  CartesianGrid,
} from 'recharts';

interface DashboardProps {
  data: any;
  onNavigate: (tab: string) => void;
}

export const DashboardPage: React.FC<DashboardProps> = ({ data, onNavigate }) => {
  const metrics = data?.metrics || {
    totalUsers: 1420,
    totalDevelopers: 5,
    verifiedDevelopers: 4,
    totalProperties: 10,
    totalProjects: 5,
    totalVerifications: 148,
    completedVerifications: 112,
    pendingVerifications: 36,
    totalPurchases: 45,
    activePurchases: 38,
    totalVolume: 845000000,
    totalPlatformFees: 12450000,
  };

  const chartData = data?.charts?.monthlyGrowth || [
    { month: 'Jan', users: 120, verifications: 45, volume: 15000000 },
    { month: 'Feb', users: 210, verifications: 68, volume: 28000000 },
    { month: 'Mar', users: 340, verifications: 95, volume: 42000000 },
    { month: 'Apr', users: 480, verifications: 130, volume: 65000000 },
    { month: 'May', users: 620, verifications: 180, volume: 88000000 },
    { month: 'Jun', users: 790, verifications: 240, volume: 110000000 },
  ];

  const propertyTypeBreakdown = data?.charts?.propertyTypeBreakdown || [
    { name: 'Residential', count: 35 },
    { name: 'Off-Plan', count: 28 },
    { name: 'Land', count: 22 },
    { name: 'Commercial', count: 15 },
  ];

  return (
    <div className="space-y-8">
      {/* Top Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Total Verification Volume */}
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm relative overflow-hidden group hover:border-emerald-500/40 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Total Verifications</span>
            <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-extrabold text-white tracking-tight">{metrics.totalVerifications}</h3>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-xs text-emerald-400 font-medium flex items-center">
                <ArrowUpRight className="w-3.5 h-3.5" /> +24%
              </span>
              <span className="text-xs text-slate-400">vs last month</span>
            </div>
          </div>
        </div>

        {/* Verified Developers */}
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm relative overflow-hidden group hover:border-emerald-500/40 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Verified Developers</span>
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 text-amber-400 flex items-center justify-center">
              <Building2 className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-extrabold text-white tracking-tight">
              {metrics.verifiedDevelopers} <span className="text-sm font-normal text-slate-400">/ {metrics.totalDevelopers} Active</span>
            </h3>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-xs text-amber-400 font-medium">100% CAC Audited</span>
            </div>
          </div>
        </div>

        {/* Total Platform Fee Revenue */}
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm relative overflow-hidden group hover:border-emerald-500/40 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Platform Fees Collected</span>
            <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <CreditCard className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-extrabold text-emerald-400 tracking-tight">
              ₦{(metrics.totalPlatformFees || 12450000).toLocaleString()}
            </h3>
            <p className="text-xs text-slate-400 mt-1">Direct Settlement Separated</p>
          </div>
        </div>

        {/* Active Purchases */}
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm relative overflow-hidden group hover:border-emerald-500/40 transition-all">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">Active Purchases</span>
            <div className="w-9 h-9 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <h3 className="text-2xl font-extrabold text-white tracking-tight">{metrics.activePurchases} Plans</h3>
            <p className="text-xs text-slate-400 mt-1">Tracking Pay-Small-Small</p>
          </div>
        </div>
      </div>

      {/* Analytics Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Verification & Transaction Volume Trend */}
        <div className="lg:col-span-2 p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-bold text-white text-base">Monthly Verification & Transaction Activity</h3>
              <p className="text-xs text-slate-400 mt-0.5">Verification requests and payment volume trends</p>
            </div>
            <div className="flex items-center gap-3 text-xs">
              <span className="flex items-center gap-1.5 text-emerald-400">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Verifications
              </span>
            </div>
          </div>

          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="colorVerif" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.5} />
                <XAxis dataKey="month" stroke="#94A3B8" fontSize={12} />
                <YAxis stroke="#94A3B8" fontSize={12} />
                <Tooltip
                  contentStyle={{ backgroundColor: '#0F172A', borderColor: '#334155', borderRadius: '8px' }}
                />
                <Area type="monotone" dataKey="verifications" stroke="#10B981" strokeWidth={2} fillOpacity={1} fill="url(#colorVerif)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Property Categories Breakdown */}
        <div className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="font-bold text-white text-base">Listing Distribution</h3>
            <p className="text-xs text-slate-400 mt-0.5">Categorization across platform inventory</p>

            <div className="h-56 mt-4">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={propertyTypeBreakdown} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.3} />
                  <XAxis type="number" stroke="#94A3B8" fontSize={11} />
                  <YAxis type="category" dataKey="name" stroke="#94A3B8" fontSize={11} width={80} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0F172A', borderColor: '#334155', borderRadius: '8px' }}
                  />
                  <Bar dataKey="count" fill="#10B981" radius={[0, 6, 6, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-800">
            <button
              onClick={() => onNavigate('properties')}
              className="w-full py-2 px-3 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-white transition-colors"
            >
              View Full Property Catalog →
            </button>
          </div>
        </div>
      </div>

      {/* Quick Action Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div
          onClick={() => onNavigate('verifications')}
          className="p-5 rounded-xl bg-gradient-to-br from-slate-900 to-emerald-950/30 border border-emerald-800/40 hover:border-emerald-500/60 cursor-pointer transition-all shadow-sm group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-emerald-400 uppercase tracking-wide">Pending Legal Review</span>
            <ShieldCheck className="w-5 h-5 text-emerald-400 group-hover:scale-110 transition-transform" />
          </div>
          <h4 className="font-bold text-white text-lg mt-2">{metrics.pendingVerifications} Requests</h4>
          <p className="text-xs text-slate-400 mt-1">Review C of O, Deed of Assignment and survey scans in queue.</p>
        </div>

        <div
          onClick={() => onNavigate('developers')}
          className="p-5 rounded-xl bg-gradient-to-br from-slate-900 to-amber-950/30 border border-amber-800/40 hover:border-amber-500/60 cursor-pointer transition-all shadow-sm group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-amber-400 uppercase tracking-wide">Developer Onboarding</span>
            <Building2 className="w-5 h-5 text-amber-400 group-hover:scale-110 transition-transform" />
          </div>
          <h4 className="font-bold text-white text-lg mt-2">1 Application Pending</h4>
          <p className="text-xs text-slate-400 mt-1">Verify CAC status, directors, and ongoing project track records.</p>
        </div>

        <div
          onClick={() => onNavigate('payments')}
          className="p-5 rounded-xl bg-gradient-to-br from-slate-900 to-blue-950/30 border border-blue-800/40 hover:border-blue-500/60 cursor-pointer transition-all shadow-sm group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-blue-400 uppercase tracking-wide">Reconciliation</span>
            <CreditCard className="w-5 h-5 text-blue-400 group-hover:scale-110 transition-transform" />
          </div>
          <h4 className="font-bold text-white text-lg mt-2">Paystack Live Sync</h4>
          <p className="text-xs text-slate-400 mt-1">Audit merchant direct settlement & fee splits.</p>
        </div>
      </div>
    </div>
  );
};

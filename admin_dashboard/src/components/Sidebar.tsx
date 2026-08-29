import React from 'react';
import {
  LayoutDashboard,
  ShieldCheck,
  Building2,
  Home,
  HardHat,
  CreditCard,
  Landmark,
  FileText,
  Calendar,
  History,
  Settings,
  LogOut,
} from 'lucide-react';

interface SidebarProps {
  currentTab: string;
  setCurrentTab: (tab: string) => void;
  currentUser?: any;
  onLogout?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ currentTab, setCurrentTab, currentUser, onLogout }) => {
  const navItems = [
    { id: 'dashboard', label: 'Overview', icon: LayoutDashboard },
    { id: 'verifications', label: 'Verification Queue', icon: ShieldCheck, badge: 'Active' },
    { id: 'developers', label: 'Verified Developers', icon: Building2 },
    { id: 'properties', label: 'Properties & Units', icon: Home },
    { id: 'projects', label: 'Off-Plan & Milestones', icon: HardHat },
    { id: 'payments', label: 'Payments & Revenue', icon: CreditCard },
    { id: 'banking', label: 'Virtual Banking & DVA', icon: Landmark },
    { id: 'legal', label: 'Legal Drafting Queue', icon: FileText },
    { id: 'inspections', label: 'Site Inspections', icon: Calendar },
    { id: 'users', label: 'User Management', icon: Building2 },
    { id: 'audit', label: 'Security & Audit Logs', icon: History },
    { id: 'settings', label: 'Fee & System Settings', icon: Settings },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-slate-300 flex flex-col border-r border-slate-800 min-h-screen shrink-0">
      {/* Brand Header */}
      <div className="p-6 border-b border-slate-800 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-emerald-600 flex items-center justify-center text-white font-bold text-xl shadow-lg shadow-emerald-900/30">
          EV
        </div>
        <div>
          <h1 className="font-bold text-white tracking-tight text-lg">EstateVerify</h1>
          <p className="text-xs text-emerald-400 font-medium tracking-wide">ADMIN CONSOLE</p>
        </div>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setCurrentTab(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-emerald-600/15 text-emerald-400 border border-emerald-500/30 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
              }`}
            >
              <div className="flex items-center gap-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-emerald-400' : 'text-slate-400'}`} />
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-emerald-900/60 text-emerald-300 border border-emerald-700/50">
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Footer / User Profile */}
      <div className="p-4 border-t border-slate-800 bg-slate-950/40">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center text-xs font-bold">
              {currentUser?.firstName?.[0] || 'A'}
            </div>
            <div className="overflow-hidden">
              <p className="text-xs font-semibold text-white truncate">
                {currentUser?.firstName ? `${currentUser.firstName} ${currentUser.lastName}` : 'Admin Director'}
              </p>
              <p className="text-[11px] text-slate-400 truncate">
                {currentUser?.email || 'admin@estateverify.ng'}
              </p>
            </div>
          </div>
          {onLogout && (
            <button
              onClick={onLogout}
              className="text-slate-400 hover:text-rose-400 p-1.5 transition-colors"
              title="Logout"
            >
              <LogOut className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
};

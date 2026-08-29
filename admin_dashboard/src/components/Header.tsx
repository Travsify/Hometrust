import React from 'react';
import { Bell, Shield, RefreshCw, LogOut, User } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle: string;
  user?: any;
  onRefresh?: () => void;
  onLogout?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ title, subtitle, user, onRefresh, onLogout }) => {
  return (
    <header className="h-16 border-b border-slate-800 bg-slate-900/60 backdrop-blur px-8 flex items-center justify-between shrink-0">
      <div>
        <h2 className="text-lg font-bold text-white tracking-tight">{title}</h2>
        <p className="text-xs text-slate-400">{subtitle}</p>
      </div>

      <div className="flex items-center gap-4">
        {/* Environment Badge */}
        <div className="hidden sm:flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-950/80 border border-emerald-800/60 text-emerald-400 text-xs font-semibold">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>Supabase PostgreSQL Connected</span>
        </div>

        {/* Global Verification Disclaimer Tag */}
        <div className="hidden md:flex items-center gap-1 text-[11px] text-amber-300/90 bg-amber-950/40 border border-amber-800/40 px-2.5 py-1 rounded-md">
          <Shield className="w-3 h-3 text-amber-400" />
          <span>Non-Custodial / Verified Gateway</span>
        </div>

        {onRefresh && (
          <button
            onClick={onRefresh}
            className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
            title="Refresh Data"
          >
            <RefreshCw className="w-4 h-4" />
          </button>
        )}

        {/* Notifications Icon */}
        <button className="relative p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-emerald-500 rounded-full"></span>
        </button>

        {/* Current User & Logout */}
        {user && (
          <div className="flex items-center gap-3 pl-3 border-l border-slate-800">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-emerald-700/40 border border-emerald-500/30 flex items-center justify-center text-emerald-400 font-bold text-xs">
                {user.firstName?.[0] || 'A'}
              </div>
              <div className="hidden lg:block text-left">
                <div className="text-xs font-semibold text-white">{user.firstName} {user.lastName}</div>
                <div className="text-[10px] text-emerald-400 font-mono font-medium uppercase">{user.role}</div>
              </div>
            </div>
            {onLogout && (
              <button
                onClick={onLogout}
                className="p-2 rounded-lg bg-slate-800/70 hover:bg-rose-950/50 hover:text-rose-400 text-slate-400 transition-colors"
                title="Log Out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            )}
          </div>
        )}
      </div>
    </header>
  );
};

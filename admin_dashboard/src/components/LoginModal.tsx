import React, { useState } from 'react';
import { ShieldCheck, Lock, Mail, AlertCircle } from 'lucide-react';
import { loginAdmin } from '../services/api';

interface LoginModalProps {
  onSuccess: (user: any) => void;
}

export const LoginModal: React.FC<LoginModalProps> = ({ onSuccess }) => {
  const [email, setEmail] = useState('admin@hometrust.ng');
  const [password, setPassword] = useState('Password123!');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const res = await loginAdmin(email, password);
      if (res.success && res.data?.user) {
        onSuccess(res.data.user);
      } else {
        setError(res.message || 'Login failed. Check your credentials.');
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Connection error. Ensure backend is running.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = (roleEmail: string) => {
    setEmail(roleEmail);
    setPassword('Password123!');
  };

  return (
    <div className="fixed inset-0 bg-slate-950/90 backdrop-blur-md flex items-center justify-center p-4 z-50">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-8 shadow-2xl">
        <div className="flex items-center gap-3 mb-6">
          <div className="p-3 bg-emerald-600/20 text-emerald-400 rounded-xl border border-emerald-500/30">
            <ShieldCheck className="w-8 h-8" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-white tracking-tight">Hometrust Admin</h2>
            <p className="text-xs text-slate-400">Secure Internal Operations Console</p>
          </div>
        </div>

        {error && (
          <div className="mb-6 p-3 bg-rose-500/10 border border-rose-500/20 rounded-xl flex items-center gap-3 text-rose-400 text-xs">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">Staff Email Address</label>
            <div className="relative">
              <Mail className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-emerald-500 transition-colors"
                placeholder="admin@hometrust.ng"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-emerald-500 transition-colors"
                placeholder="••••••••"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-semibold py-3 rounded-xl transition-all shadow-lg shadow-emerald-900/30 flex items-center justify-center gap-2 mt-2"
          >
            {loading ? 'Authenticating...' : 'Sign In to Dashboard'}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-slate-800">
          <p className="text-xs font-medium text-slate-400 mb-3">Quick Demo Staff Accounts:</p>
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button"
              onClick={() => handleQuickFill('admin@hometrust.ng')}
              className="text-left px-3 py-2 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 rounded-lg text-xs transition-colors"
            >
              <div className="font-semibold text-emerald-400">Super Admin</div>
              <div className="text-[10px] text-slate-400 truncate">admin@hometrust.ng</div>
            </button>
            <button
              type="button"
              onClick={() => handleQuickFill('legal@hometrust.ng')}
              className="text-left px-3 py-2 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 rounded-lg text-xs transition-colors"
            >
              <div className="font-semibold text-amber-400">Legal Manager</div>
              <div className="text-[10px] text-slate-400 truncate">legal@hometrust.ng</div>
            </button>
            <button
              type="button"
              onClick={() => handleQuickFill('verification@hometrust.ng')}
              className="text-left px-3 py-2 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 rounded-lg text-xs transition-colors"
            >
              <div className="font-semibold text-blue-400">Verification Officer</div>
              <div className="text-[10px] text-slate-400 truncate">verification@hometrust.ng</div>
            </button>
            <button
              type="button"
              onClick={() => handleQuickFill('finance@hometrust.ng')}
              className="text-left px-3 py-2 bg-slate-800/50 hover:bg-slate-800 border border-slate-700/50 rounded-lg text-xs transition-colors"
            >
              <div className="font-semibold text-purple-400">Finance Manager</div>
              <div className="text-[10px] text-slate-400 truncate">finance@hometrust.ng</div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

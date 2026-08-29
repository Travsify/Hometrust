import React, { useState, useEffect } from 'react';
import { History, Shield, Lock, Search, RefreshCw } from 'lucide-react';
import { getAuditLogs } from '../services/api';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const data = await getAuditLogs();
      setLogs(data.logs || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const filtered = logs.filter(
    (l) =>
      !searchTerm ||
      l.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.adminEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
      l.entityType.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Compliance Header */}
      <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
            <Lock className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-bold text-white text-base">Immutable Security & Regulatory Audit Logs</h3>
            <p className="text-xs text-slate-400">
              NDPR-compliant tamper-evident operational logs recorded for all administrative overrides, verifications, and approvals.
            </p>
          </div>
        </div>

        <button
          onClick={fetchLogs}
          className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      <div className="rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden shadow-sm">
        <table className="w-full text-left text-xs">
          <thead className="bg-slate-950/60 text-slate-400 uppercase tracking-wider border-b border-slate-800 font-semibold">
            <tr>
              <th className="px-6 py-4">Timestamp (UTC)</th>
              <th className="px-6 py-4">Admin Actor</th>
              <th className="px-6 py-4">Action</th>
              <th className="px-6 py-4">Target Entity</th>
              <th className="px-6 py-4">Context Details</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {filtered.map((log) => (
              <tr key={log.id} className="hover:bg-slate-800/40 transition-colors">
                <td className="px-6 py-4 font-mono text-slate-400">
                  {new Date(log.createdAt).toLocaleString()}
                </td>
                <td className="px-6 py-4 font-semibold text-white">
                  {log.adminEmail}
                </td>
                <td className="px-6 py-4">
                  <span className="px-2 py-0.5 rounded bg-emerald-950 text-emerald-400 border border-emerald-800 font-mono text-[11px]">
                    {log.action}
                  </span>
                </td>
                <td className="px-6 py-4 font-mono text-slate-300">
                  {log.entityType} ({log.entityId?.slice(0, 8)}...)
                </td>
                <td className="px-6 py-4 font-mono text-slate-400 text-[11px] max-w-xs truncate">
                  {JSON.stringify(log.details)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

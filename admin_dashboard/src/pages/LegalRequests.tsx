import React, { useState, useEffect } from 'react';
import { FileText, Download, CheckCircle2, Clock, UploadCloud, Search } from 'lucide-react';
import { getLegalRequests, updateLegalRequest } from '../services/api';

export const LegalRequestsPage: React.FC = () => {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedReq, setSelectedReq] = useState<any | null>(null);
  const [draftUrl, setDraftUrl] = useState<string>('');

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const data = await getLegalRequests();
      setRequests(data.requests || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  const handleUpdate = async (status: string) => {
    if (!selectedReq) return;
    try {
      await updateLegalRequest(selectedReq.id, {
        status,
        finalDocumentUrl: draftUrl || selectedReq.finalDocumentUrl || 'http://localhost:5000/api/v1/storage/files/sample_deed_final.docx',
      });
      await fetchRequests();
      setSelectedReq(null);
    } catch (err) {
      alert('Failed to update legal request');
    }
  };

  return (
    <div className="space-y-6">
      <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
        <div>
          <h3 className="font-bold text-white text-base">EstateVerify Legal & Verification Team Queue</h3>
          <p className="text-xs text-slate-400 mt-0.5">Professional document preparation: Deeds of Assignment, Contracts of Sale, Tenancy & Leases</p>
        </div>
      </div>

      <div className="rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden shadow-sm">
        <table className="w-full text-left text-xs">
          <thead className="bg-slate-950/60 text-slate-400 uppercase tracking-wider border-b border-slate-800 font-semibold">
            <tr>
              <th className="px-6 py-4">Request Code</th>
              <th className="px-6 py-4">Category / Title</th>
              <th className="px-6 py-4">Applicant</th>
              <th className="px-6 py-4">Fee Paid</th>
              <th className="px-6 py-4">Status</th>
              <th className="px-6 py-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800">
            {requests.map((r) => (
              <tr key={r.id} className="hover:bg-slate-800/40 transition-colors">
                <td className="px-6 py-4 font-mono font-bold text-emerald-400">{r.requestCode}</td>
                <td className="px-6 py-4">
                  <div className="font-bold text-white">{r.title}</div>
                  <div className="text-slate-400 text-[11px] font-mono">{r.documentCategory}</div>
                </td>
                <td className="px-6 py-4">
                  <div className="text-white">{r.user?.firstName} {r.user?.lastName}</div>
                  <div className="text-slate-400 text-[11px]">{r.user?.email}</div>
                </td>
                <td className="px-6 py-4 font-bold text-emerald-400">
                  ₦{r.feeAmount?.toLocaleString()}
                </td>
                <td className="px-6 py-4">
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-blue-950 text-blue-300 border border-blue-800">
                    {r.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <button
                    onClick={() => setSelectedReq(r)}
                    className="px-3 py-1.5 rounded-lg bg-emerald-600/20 hover:bg-emerald-600 text-emerald-400 hover:text-white border border-emerald-500/40 text-xs font-semibold transition-all"
                  >
                    Drafting Console
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedReq && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl p-6 space-y-5 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <div>
                <span className="font-mono text-emerald-400 font-bold text-xs">{selectedReq.requestCode}</span>
                <h3 className="text-base font-bold text-white mt-0.5">{selectedReq.title}</h3>
              </div>
              <button onClick={() => setSelectedReq(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 space-y-1 text-xs">
              <p className="text-slate-400 font-semibold uppercase">Client Instructions / Requirements:</p>
              <p className="text-slate-300">{selectedReq.requirements}</p>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-bold text-slate-300">Upload Draft or Final Document URL</label>
              <input
                type="text"
                placeholder="http://localhost:5000/api/v1/storage/files/..."
                value={draftUrl}
                onChange={(e) => setDraftUrl(e.target.value)}
                className="w-full p-2.5 rounded-lg bg-slate-950 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              <button
                onClick={() => handleUpdate('DRAFTING')}
                className="px-4 py-2 rounded-lg bg-slate-800 text-slate-300 hover:bg-slate-700 text-xs font-semibold"
              >
                Mark In Drafting
              </button>
              <button
                onClick={() => handleUpdate('FINALIZED')}
                className="px-5 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-lg shadow-emerald-900/40"
              >
                Finalize & Deliver Document
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

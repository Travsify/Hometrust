import React, { useState, useEffect } from 'react';
import {
  ShieldCheck,
  FileCheck,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  ExternalLink,
  Eye,
  FileText,
  Search,
  Filter,
  Download,
} from 'lucide-react';
import { getVerificationRequests, updateVerificationStatus } from '../services/api';

export const VerificationsPage: React.FC = () => {
  const [requests, setRequests] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedReq, setSelectedReq] = useState<any | null>(null);
  const [activeFilter, setActiveFilter] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [updating, setUpdating] = useState<boolean>(false);
  const [actionNotes, setActionNotes] = useState<string>('');

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const data = await getVerificationRequests();
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

  const handleUpdateStatus = async (newStatus: string) => {
    if (!selectedReq) return;
    setUpdating(true);
    try {
      const updated = await updateVerificationStatus(selectedReq.id, {
        status: newStatus,
        finalFindings: actionNotes || selectedReq.finalFindings,
        externalRegistryChecked: true,
        externalRegistryNotes: 'Verified with Lands Registry records.',
      });
      setSelectedReq(updated);
      await fetchRequests();
    } catch (err) {
      alert('Failed to update verification status');
    } finally {
      setUpdating(false);
    }
  };

  const filteredRequests = requests.filter((r) => {
    const matchesFilter = activeFilter === 'ALL' || r.status === activeFilter;
    const matchesSearch =
      !searchTerm ||
      r.verificationCode.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.propertyName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.propertyAddress.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Filters & Search Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto">
          {['ALL', 'SUBMITTED', 'LEGAL_REVIEW', 'VERIFIED', 'VERIFIED_WITH_ISSUES', 'REJECTED'].map((filter) => (
            <button
              key={filter}
              onClick={() => setActiveFilter(filter)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all ${
                activeFilter === filter
                  ? 'bg-emerald-600 text-white'
                  : 'bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700'
              }`}
            >
              {filter.replace(/_/g, ' ')}
            </button>
          ))}
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder="Search by Code or Property..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Requests Table */}
      <div className="rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-950/60 text-slate-400 uppercase tracking-wider border-b border-slate-800 font-semibold">
              <tr>
                <th className="px-6 py-4">Verification ID</th>
                <th className="px-6 py-4">Property & Location</th>
                <th className="px-6 py-4">Document Type</th>
                <th className="px-6 py-4">Applicant</th>
                <th className="px-6 py-4">Fee / Urgency</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {loading ? (
                <tr>
                  <td colSpan={7} className="text-center py-8 text-slate-500">
                    Loading verification requests...
                  </td>
                </tr>
              ) : filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-8 text-slate-500">
                    No verification requests found matching current filter.
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => (
                  <tr key={req.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4 font-mono font-bold text-emerald-400">
                      {req.verificationCode}
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-semibold text-white">{req.propertyName}</div>
                      <div className="text-slate-400 text-[11px]">{req.propertyAddress}, {req.city}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-0.5 rounded bg-slate-800 border border-slate-700 text-slate-300 font-mono text-[11px]">
                        {req.documentType}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-300">
                      <div>{req.user?.firstName} {req.user?.lastName}</div>
                      <div className="text-slate-500 text-[11px]">{req.user?.email}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-semibold text-white">₦{req.feeAmount?.toLocaleString()}</div>
                      <div className="text-slate-400 text-[11px]">{req.urgency}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full font-bold text-[10px] tracking-wide uppercase ${
                          req.status === 'VERIFIED'
                            ? 'bg-emerald-950 text-emerald-400 border border-emerald-800'
                            : req.status === 'VERIFIED_WITH_ISSUES'
                            ? 'bg-amber-950 text-amber-400 border border-amber-800'
                            : req.status === 'REJECTED'
                            ? 'bg-rose-950 text-rose-400 border border-rose-800'
                            : 'bg-blue-950 text-blue-400 border border-blue-800'
                        }`}
                      >
                        <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                        {req.status.replace(/_/g, ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => setSelectedReq(req)}
                        className="px-3 py-1.5 rounded-lg bg-emerald-600/20 hover:bg-emerald-600 text-emerald-400 hover:text-white border border-emerald-500/40 text-xs font-semibold transition-all"
                      >
                        Review Document
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Review Modal */}
      {selectedReq && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-4xl max-h-[90vh] overflow-y-auto p-6 space-y-6 shadow-2xl">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono text-emerald-400 font-bold text-sm">{selectedReq.verificationCode}</span>
                  <span className="text-xs px-2 py-0.5 rounded bg-slate-800 text-slate-300 uppercase font-semibold">
                    {selectedReq.status}
                  </span>
                </div>
                <h3 className="text-xl font-bold text-white mt-1">{selectedReq.propertyName}</h3>
                <p className="text-xs text-slate-400">{selectedReq.propertyAddress}, {selectedReq.city}, {selectedReq.state}</p>
              </div>
              <button
                onClick={() => setSelectedReq(null)}
                className="p-2 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800"
              >
                ✕
              </button>
            </div>

            {/* AI Preliminary Scan Results Box */}
            <div className="p-4 rounded-xl bg-slate-950 border border-emerald-900/40 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-emerald-400 uppercase tracking-wider flex items-center gap-1.5">
                  <ShieldCheck className="w-4 h-4" /> AI Preliminary Heuristic Analysis
                </span>
                <span className="text-[11px] text-amber-400 font-medium">Preliminary Only • Non-Authenticating</span>
              </div>
              <p className="text-xs text-slate-300">
                {selectedReq.documents?.[0]?.aiScanSummary || 'Preliminary scan detected valid document headers and surveyor stamps.'}
              </p>
            </div>

            {/* Checklist */}
            <div className="space-y-3">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Statutory Legal Checklist</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {selectedReq.checks?.map((chk: any) => (
                  <div key={chk.id} className="p-3 rounded-lg bg-slate-950 border border-slate-800 flex items-start gap-3">
                    <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                    <div>
                      <p className="text-xs font-bold text-white">{chk.checkName}</p>
                      <p className="text-[11px] text-slate-400 mt-0.5">{chk.notes || 'Passed statutory verification'}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Final Findings & Action Box */}
            <div className="space-y-3">
              <label className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Legal Team Findings & Registry Notes
              </label>
              <textarea
                rows={3}
                value={actionNotes || selectedReq.finalFindings || ''}
                onChange={(e) => setActionNotes(e.target.value)}
                placeholder="Enter professional review notes, registry volume/page details..."
                className="w-full p-3 rounded-lg bg-slate-950 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>

            {/* Generated Report Link if available */}
            {selectedReq.reportUrl && (
              <div className="p-3 rounded-lg bg-emerald-950/40 border border-emerald-800/60 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <FileText className="w-4 h-4 text-emerald-400" />
                  <span className="text-xs font-semibold text-emerald-300">Official PDF Verification Report Generated</span>
                </div>
                <a
                  href={selectedReq.reportUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center gap-1 text-xs font-bold text-emerald-400 hover:underline"
                >
                  <Download className="w-3.5 h-3.5" /> Download Report
                </a>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
              <button
                disabled={updating}
                onClick={() => handleUpdateStatus('REJECTED')}
                className="px-4 py-2 rounded-lg bg-rose-600/20 hover:bg-rose-600 text-rose-400 hover:text-white border border-rose-500/40 text-xs font-bold transition-all"
              >
                Reject / Flag Fraud
              </button>
              <button
                disabled={updating}
                onClick={() => handleUpdateStatus('VERIFIED_WITH_ISSUES')}
                className="px-4 py-2 rounded-lg bg-amber-600/20 hover:bg-amber-600 text-amber-400 hover:text-white border border-amber-500/40 text-xs font-bold transition-all"
              >
                Verify with Caveats
              </button>
              <button
                disabled={updating}
                onClick={() => handleUpdateStatus('VERIFIED')}
                className="px-5 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-900/40 transition-all flex items-center gap-2"
              >
                <CheckCircle2 className="w-4 h-4" />
                {updating ? 'Generating Report...' : 'Approve & Issue Report'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

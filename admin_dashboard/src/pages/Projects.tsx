import React, { useState, useEffect } from 'react';
import {
  HardHat,
  CheckCircle2,
  Clock,
  AlertCircle,
  Search,
  ShieldCheck,
  Video,
  FileText,
  DollarSign,
  AlertTriangle,
  ExternalLink,
  ChevronRight,
  UserCheck,
} from 'lucide-react';
import { getProjects, updateMilestone, getAdminMilestones, adminDisburseMilestone } from '../services/api';

export const ProjectsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'PROJECTS' | 'MILESTONES'>('MILESTONES');
  const [projects, setProjects] = useState<any[]>([]);
  const [milestones, setMilestones] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [updating, setUpdating] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedMilestone, setSelectedMilestone] = useState<any | null>(null);
  const [remediationNotes, setRemediationNotes] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [projData, mileData] = await Promise.all([
        getProjects().catch(() => ({ projects: [] })),
        getAdminMilestones().catch(() => ({ milestones: [] })),
      ]);
      setProjects(projData?.projects || []);
      setMilestones(mileData?.milestones || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  const handleMilestoneUpdate = async (milestoneId: string, percentage: number, status: string) => {
    setUpdating(true);
    try {
      await updateMilestone(milestoneId, {
        percentage,
        status,
        verifiedBy: 'Hometrust Technical Inspection Team',
      });
      await fetchAllData();
    } catch (err) {
      alert('Failed to update milestone');
    } finally {
      setUpdating(false);
    }
  };

  const handleGovernanceAction = async (milestoneId: string, action: 'DISBURSE' | 'DISPUTE' | 'REMEDIATION_REQUIRED') => {
    setActionLoading(true);
    try {
      await adminDisburseMilestone(milestoneId, action, remediationNotes);
      alert(`Milestone successfully updated: ${action}`);
      setSelectedMilestone(null);
      setRemediationNotes('');
      await fetchAllData();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to execute escrow action');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredMilestones = milestones.filter(
    (m) =>
      !searchTerm ||
      m.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.project?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.project?.developer?.companyName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.corenLicenseNumber?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredProjects = projects.filter(
    (p) =>
      !searchTerm ||
      p.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.developer?.companyName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.city?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setActiveTab('MILESTONES')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'MILESTONES'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            Milestone Proof Packs & Escrow ({milestones.length})
          </button>
          <button
            onClick={() => setActiveTab('PROJECTS')}
            className={`px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'PROJECTS'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            <HardHat className="w-4 h-4" />
            Off-Plan Projects ({projects.length})
          </button>
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder={activeTab === 'MILESTONES' ? 'Search Milestone, Project, COREN...' : 'Search Project, Location...'}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      {/* MILESTONES TAB */}
      {activeTab === 'MILESTONES' && (
        <div className="space-y-4">
          {loading ? (
            <div className="text-center py-16 text-slate-500">Loading milestone verification requests...</div>
          ) : filteredMilestones.length === 0 ? (
            <div className="p-12 text-center rounded-2xl bg-slate-900 border border-slate-800 text-slate-500">
              <ShieldCheck className="w-12 h-12 text-slate-600 mx-auto mb-3" />
              <p className="font-bold text-slate-400">No milestone proof submissions in queue.</p>
              <p className="text-xs text-slate-500 mt-1">Developers submit COREN engineer certificates and live walkthrough videos here.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {filteredMilestones.map((m) => {
                const totalVotes = (m.approvalsCount || 0) + (m.disputesCount || 0);
                const approvalRate = totalVotes > 0 ? Math.round(((m.approvalsCount || 0) / totalVotes) * 100) : 0;

                return (
                  <div
                    key={m.id}
                    className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm hover:border-slate-700 transition-all flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6"
                  >
                    <div className="space-y-3 flex-1">
                      <div className="flex flex-wrap items-center gap-2.5">
                        <span className="font-bold text-white text-base">{m.title}</span>
                        <span className="text-xs text-emerald-400 font-semibold px-2 py-0.5 rounded bg-emerald-950/60 border border-emerald-800">
                          {m.percentage}% Target
                        </span>
                        {m.payoutStatus === 'DISBURSED' ? (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-900 text-emerald-300 border border-emerald-700">
                            ESCROW DISBURSED
                          </span>
                        ) : m.status === 'IN_REVIEW' ? (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-amber-900 text-amber-300 border border-amber-700 animate-pulse">
                            5-DAY SUBSCRIBER REVIEW ACTIVE
                          </span>
                        ) : (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                            {m.status}
                          </span>
                        )}
                      </div>

                      <div className="text-xs text-slate-400 flex flex-wrap gap-y-1 gap-x-4">
                        <span>🏢 <strong>Project:</strong> {m.project?.name || 'N/A'}</span>
                        <span>🏗️ <strong>Developer:</strong> {m.project?.developer?.companyName || 'N/A'}</span>
                        <span>💰 <strong>Tranche:</strong> ₦{(m.trancheAmount || 0).toLocaleString()}</span>
                      </div>

                      {/* COREN Engineer & Verification Data */}
                      <div className="p-3 rounded-xl bg-slate-950 border border-slate-800/80 grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                        <div>
                          <span className="text-[10px] uppercase font-bold text-slate-500 block">Lead Structural Engineer</span>
                          <span className="font-semibold text-slate-200">{m.corenEngineerName || 'Not Provided'}</span>
                          <span className="text-[11px] text-emerald-400 block font-mono">
                            {m.corenLicenseNumber ? `COREN: ${m.corenLicenseNumber}` : 'Unlicensed'}
                          </span>
                        </div>

                        <div>
                          <span className="text-[10px] uppercase font-bold text-slate-500 block">Subscriber Consensus</span>
                          <div className="flex items-center gap-2 mt-0.5">
                            <span className="text-emerald-400 font-bold">👍 {m.approvalsCount || 0}</span>
                            <span className="text-red-400 font-bold">⚠️ {m.disputesCount || 0}</span>
                            <span className="text-slate-400 text-[11px]">({approvalRate}% Approval)</span>
                          </div>
                        </div>

                        <div>
                          <span className="text-[10px] uppercase font-bold text-slate-500 block">Proof Media & Links</span>
                          <div className="flex items-center gap-2 mt-1">
                            {m.walkthroughVideoUrl && (
                              <a
                                href={m.walkthroughVideoUrl}
                                target="_blank"
                                rel="noreferrer"
                                className="px-2 py-1 rounded bg-blue-950 text-blue-300 border border-blue-800 text-[10px] font-bold flex items-center gap-1 hover:bg-blue-900"
                              >
                                <Video className="w-3 h-3" /> 360° Video
                              </a>
                            )}
                            {m.corenCertificateUrl && (
                              <a
                                href={m.corenCertificateUrl}
                                target="_blank"
                                rel="noreferrer"
                                className="px-2 py-1 rounded bg-emerald-950 text-emerald-300 border border-emerald-800 text-[10px] font-bold flex items-center gap-1 hover:bg-emerald-900"
                              >
                                <FileText className="w-3 h-3" /> Valuation Cert
                              </a>
                            )}
                            {m.testReportUrl && (
                              <a
                                href={m.testReportUrl}
                                target="_blank"
                                rel="noreferrer"
                                className="px-2 py-1 rounded bg-amber-950 text-amber-300 border border-amber-800 text-[10px] font-bold flex items-center gap-1 hover:bg-amber-900"
                              >
                                <FileText className="w-3 h-3" /> Test Report
                              </a>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex flex-col gap-2 w-full lg:w-auto">
                      <button
                        onClick={() => setSelectedMilestone(m)}
                        className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center justify-center gap-1.5 shadow-sm transition-all"
                      >
                        <ShieldCheck className="w-4 h-4" /> Escrow Governance →
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* PROJECTS TAB */}
      {activeTab === 'PROJECTS' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {loading ? (
            <div className="col-span-2 text-center py-12 text-slate-500">Loading off-plan projects...</div>
          ) : filteredProjects.length === 0 ? (
            <div className="col-span-2 text-center py-12 text-slate-500">No off-plan projects found.</div>
          ) : (
            filteredProjects.map((proj) => (
              <div key={proj.id} className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-5">
                <div className="flex items-start justify-between">
                  <div>
                    <h4 className="font-bold text-white text-lg">{proj.name}</h4>
                    <p className="text-xs text-emerald-400 font-medium mt-0.5">
                      {proj.developer?.companyName} • {proj.area}, {proj.city}
                    </p>
                  </div>
                  <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-blue-950 text-blue-300 border border-blue-800">
                    Target: {proj.expectedCompletion}
                  </span>
                </div>

                {/* Milestones Visual Timeline */}
                <div className="space-y-3 pt-2">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Construction Milestones</span>
                  <div className="space-y-2">
                    {proj.milestones?.map((m: any) => (
                      <div key={m.id} className="p-3 rounded-lg bg-slate-950 border border-slate-800 flex items-center justify-between">
                        <div className="space-y-1 flex-1 pr-4">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-bold text-white">{m.title}</span>
                            <span className="font-mono text-emerald-400 font-bold">{m.percentage}%</span>
                          </div>
                          <div className="w-full bg-slate-800 h-1.5 rounded-full overflow-hidden">
                            <div
                              className="bg-emerald-500 h-full rounded-full transition-all duration-500"
                              style={{ width: `${m.percentage}%` }}
                            ></div>
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5">
                          {m.percentage === 100 ? (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-950 text-emerald-400 border border-emerald-800">
                              COMPLETED
                            </span>
                          ) : (
                            <button
                              disabled={updating}
                              onClick={() => handleMilestoneUpdate(m.id, Math.min(100, m.percentage + 25), m.percentage + 25 >= 100 ? 'COMPLETED' : 'IN_PROGRESS')}
                              className="px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 text-[11px] font-semibold border border-slate-700 transition-colors"
                            >
                              +25% Progress
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Units Summary */}
                <div className="pt-3 border-t border-slate-800 flex items-center justify-between text-xs">
                  <span className="text-slate-400">Inventory Units:</span>
                  <span className="font-bold text-white">
                    {proj.availableUnits} Available / {proj.totalUnits} Total
                  </span>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* ESCROW GOVERNANCE MODAL */}
      {selectedMilestone && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-xl overflow-hidden shadow-2xl space-y-5 p-6">
            <div className="flex items-start justify-between border-b border-slate-800 pb-4">
              <div>
                <h3 className="font-bold text-white text-lg flex items-center gap-2">
                  <ShieldCheck className="w-5 h-5 text-emerald-400" />
                  Escrow Tranche Governance
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">
                  {selectedMilestone.project?.name} • {selectedMilestone.title} ({selectedMilestone.percentage}%)
                </p>
              </div>
              <button
                onClick={() => setSelectedMilestone(null)}
                className="text-slate-400 hover:text-white text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 space-y-2">
                <div className="flex justify-between">
                  <span className="text-slate-400">Requested Tranche Payout:</span>
                  <span className="font-bold text-emerald-400 font-mono text-sm">
                    ₦{(selectedMilestone.trancheAmount || 0).toLocaleString()}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">COREN Structural Engineer:</span>
                  <span className="font-bold text-white">
                    {selectedMilestone.corenEngineerName || 'N/A'} ({selectedMilestone.corenLicenseNumber || 'Unverified'})
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Current Payout Status:</span>
                  <span className="font-bold text-amber-400">{selectedMilestone.payoutStatus || 'PENDING'}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Subscriber Votes:</span>
                  <span className="font-bold text-slate-200">
                    {selectedMilestone.approvalsCount || 0} Approvals / {selectedMilestone.disputesCount || 0} Disputes
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-slate-400 text-xs font-semibold mb-1">Remediation / Inspection Notes</label>
                <textarea
                  rows={3}
                  value={remediationNotes}
                  onChange={(e) => setRemediationNotes(e.target.value)}
                  placeholder="Enter audit observations, punch-list remediation instructions or escrow approval authorization details..."
                  className="w-full p-3 rounded-xl bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                ></textarea>
              </div>
            </div>

            <div className="grid grid-cols-3 gap-3 pt-2">
              <button
                disabled={actionLoading}
                onClick={() => handleGovernanceAction(selectedMilestone.id, 'DISBURSE')}
                className="py-2.5 px-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm transition-all"
              >
                <CheckCircle2 className="w-4 h-4" /> Disburse Tranche
              </button>

              <button
                disabled={actionLoading}
                onClick={() => handleGovernanceAction(selectedMilestone.id, 'DISPUTE')}
                className="py-2.5 px-3 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm transition-all"
              >
                <AlertTriangle className="w-4 h-4" /> Flag Dispute
              </button>

              <button
                disabled={actionLoading}
                onClick={() => handleGovernanceAction(selectedMilestone.id, 'REMEDIATION_REQUIRED')}
                className="py-2.5 px-3 rounded-xl bg-amber-600 hover:bg-amber-500 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-sm transition-all"
              >
                <Clock className="w-4 h-4" /> Request Remediation
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

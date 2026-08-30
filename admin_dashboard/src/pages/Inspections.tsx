import React, { useState, useEffect } from 'react';
import {
  Calendar,
  MapPin,
  Clock,
  UserCheck,
  Search,
  ShieldCheck,
  Video,
  FileText,
  DollarSign,
  AlertTriangle,
  ExternalLink,
  CheckCircle2,
  Ticket,
} from 'lucide-react';
import { api } from '../services/api';

export const InspectionsPage: React.FC = () => {
  const [inspections, setInspections] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedFilter, setSelectedFilter] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedInspection, setSelectedInspection] = useState<any | null>(null);
  const [modalMode, setModalMode] = useState<'ASSIGN_COREN' | 'SUBMIT_REPORT' | null>(null);
  
  // COREN Form states
  const [engineerName, setEngineerName] = useState<string>('');
  const [licenseNumber, setLicenseNumber] = useState<string>('');
  const [reportUrl, setReportUrl] = useState<string>('');
  const [structuralScore, setStructuralScore] = useState<number>(90);
  const [defectNotes, setDefectNotes] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const fetchInspections = async () => {
    setLoading(true);
    try {
      const res = await api.get('/inspections/all');
      setInspections(res.data.data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInspections();
  }, []);

  const handleAssignCoren = async () => {
    if (!selectedInspection || !engineerName || !licenseNumber) return;
    setActionLoading(true);
    try {
      await api.post(`/inspections/${selectedInspection.id}/assign-coren`, {
        engineerName,
        licenseNumber,
      });
      alert('COREN Engineer successfully assigned.');
      setSelectedInspection(null);
      setModalMode(null);
      await fetchInspections();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to assign COREN engineer');
    } finally {
      setActionLoading(false);
    }
  };

  const handleSubmitReport = async () => {
    if (!selectedInspection || !reportUrl) return;
    setActionLoading(true);
    try {
      await api.post(`/inspections/${selectedInspection.id}/coren-report`, {
        reportUrl,
        structuralScore,
        defectNotes,
        status: 'COMPLETED',
      });
      alert('COREN Inspection Report uploaded.');
      setSelectedInspection(null);
      setModalMode(null);
      await fetchInspections();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to submit report');
    } finally {
      setActionLoading(false);
    }
  };

  const filteredInspections = inspections.filter((ins) => {
    const matchesFilter =
      selectedFilter === 'ALL' ||
      (selectedFilter === 'COREN' && ins.inspectionType === 'COREN_ENGINEER') ||
      (selectedFilter === 'SELF' && ins.inspectionType === 'SELF_OR_REPRESENTATIVE') ||
      (selectedFilter === 'VIDEO' && ins.inspectionType === 'GEOFENCED_VIDEO');

    const matchesSearch =
      !searchTerm ||
      ins.attendeeName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ins.property?.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ins.project?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ins.gatePassCode?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ins.corenLicenseNumber?.toLowerCase().includes(searchTerm.toLowerCase());

    return matchesFilter && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div>
          <h3 className="font-bold text-white text-base">Site Inspections & COREN Engineering Audits</h3>
          <p className="text-xs text-slate-400 mt-0.5">Physical gate passes, accredited COREN structural reviews (₦25k) & geofenced live videos</p>
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder="Search Attendee, Gate Pass, COREN..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2">
        {[
          { id: 'ALL', label: 'All Inspections' },
          { id: 'COREN', label: 'COREN Structural Audits (₦25,000)' },
          { id: 'SELF', label: 'Self / Representative Passes (₦0)' },
          { id: 'VIDEO', label: 'Geofenced Live Videos' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setSelectedFilter(tab.id)}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
              selectedFilter === tab.id
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-slate-900 border border-slate-800 text-slate-400 hover:text-white'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Inspections Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {loading ? (
          <div className="col-span-3 text-center py-16 text-slate-500">Loading inspection records...</div>
        ) : filteredInspections.length === 0 ? (
          <div className="col-span-3 text-center py-16 p-8 rounded-2xl bg-slate-900 border border-slate-800 text-slate-500">
            No inspection bookings found for this category.
          </div>
        ) : (
          filteredInspections.map((ins) => {
            const isCoren = ins.inspectionType === 'COREN_ENGINEER';
            const isVideo = ins.inspectionType === 'GEOFENCED_VIDEO';

            return (
              <div
                key={ins.id}
                className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-4 flex flex-col justify-between hover:border-slate-700 transition-all"
              >
                <div className="space-y-3">
                  {/* Type Badge & Status */}
                  <div className="flex items-center justify-between">
                    <span
                      className={`text-[10px] font-bold px-2.5 py-1 rounded-full border ${
                        isCoren
                          ? 'bg-blue-950 text-blue-300 border-blue-800'
                          : isVideo
                          ? 'bg-purple-950 text-purple-300 border-purple-800'
                          : 'bg-emerald-950 text-emerald-300 border-emerald-800'
                      }`}
                    >
                      {isCoren ? '🏛️ COREN AUDIT (₦25,000)' : isVideo ? '📹 GEOFENCED VIDEO' : '🎟️ GATE PASS (₦0)'}
                    </span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-slate-800 text-slate-300">
                      {ins.status}
                    </span>
                  </div>

                  {/* Property / Project Title */}
                  <div>
                    <h4 className="font-bold text-white text-sm">
                      {ins.property?.title || ins.project?.name || 'Property / Site Inspection'}
                    </h4>
                    <div className="flex items-center gap-1 text-[11px] text-slate-400 mt-1">
                      <Clock className="w-3 h-3 text-emerald-400" />
                      <span>{ins.preferredDate} • {ins.preferredTime}</span>
                    </div>
                  </div>

                  {/* Gate Pass Code or COREN Details */}
                  {ins.gatePassCode && !isCoren && (
                    <div className="p-2.5 rounded-xl bg-slate-950 border border-slate-800/80 flex items-center justify-between">
                      <span className="text-[10px] uppercase font-bold text-slate-500 flex items-center gap-1">
                        <Ticket className="w-3 h-3 text-emerald-400" /> Gate Pass:
                      </span>
                      <span className="font-mono font-bold text-emerald-400 text-xs">{ins.gatePassCode}</span>
                    </div>
                  )}

                  {isCoren && (
                    <div className="p-3 rounded-xl bg-slate-950 border border-slate-800/80 text-xs space-y-1.5">
                      <div className="flex justify-between">
                        <span className="text-slate-400">Assigned Engineer:</span>
                        <span className="font-bold text-white">{ins.corenEngineerName || 'Unassigned'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400">COREN Number:</span>
                        <span className="font-mono text-emerald-400">{ins.corenLicenseNumber || 'N/A'}</span>
                      </div>
                      {ins.structuralScore && (
                        <div className="flex justify-between">
                          <span className="text-slate-400">Compliance Score:</span>
                          <span className="font-bold text-emerald-400">{ins.structuralScore}/100</span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Attendee Info */}
                  <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 text-xs space-y-1">
                    <p className="font-semibold text-white">
                      {ins.representativeName ? `Rep: ${ins.representativeName}` : `Attendee: ${ins.attendeeName}`}
                    </p>
                    <p className="text-slate-400">Phone: {ins.representativePhone || ins.attendeePhone}</p>
                    <p className="text-slate-400">Email: {ins.attendeeEmail}</p>
                    {ins.notes && <p className="text-slate-500 text-[11px] pt-1 italic">"{ins.notes}"</p>}
                  </div>
                </div>

                {/* Actions */}
                <div className="pt-2 border-t border-slate-800 flex items-center justify-between gap-2">
                  {isCoren && (
                    <>
                      {!ins.corenEngineerName ? (
                        <button
                          onClick={() => {
                            setSelectedInspection(ins);
                            setModalMode('ASSIGN_COREN');
                          }}
                          className="w-full py-2 px-3 rounded-lg bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                        >
                          <ShieldCheck className="w-3.5 h-3.5" /> Assign Engineer
                        </button>
                      ) : !ins.corenReportUrl ? (
                        <button
                          onClick={() => {
                            setSelectedInspection(ins);
                            setModalMode('SUBMIT_REPORT');
                          }}
                          className="w-full py-2 px-3 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                        >
                          <FileText className="w-3.5 h-3.5" /> Upload Report
                        </button>
                      ) : (
                        <a
                          href={ins.corenReportUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="w-full py-2 px-3 rounded-lg bg-slate-800 hover:bg-slate-700 text-emerald-400 text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                        >
                          <ExternalLink className="w-3.5 h-3.5" /> View Stamped Report
                        </a>
                      )}
                    </>
                  )}

                  {isVideo && ins.geofencedVideoUrl && (
                    <a
                      href={ins.geofencedVideoUrl}
                      target="_blank"
                      rel="noreferrer"
                      className="w-full py-2 px-3 rounded-lg bg-purple-950 hover:bg-purple-900 text-purple-300 border border-purple-800 text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
                    >
                      <Video className="w-3.5 h-3.5" /> Play Geofenced Video
                    </a>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* ASSIGN COREN MODAL */}
      {selectedInspection && modalMode === 'ASSIGN_COREN' && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6 space-y-4 shadow-2xl">
            <div className="flex justify-between items-start border-b border-slate-800 pb-3">
              <div>
                <h3 className="font-bold text-white text-base">Assign Certified COREN Engineer</h3>
                <p className="text-xs text-slate-400 mt-0.5">Physical structural verification (Fee: ₦25,000)</p>
              </div>
              <button onClick={() => setModalMode(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block text-slate-400 font-semibold mb-1">Lead Structural Engineer Name</label>
                <input
                  type="text"
                  placeholder="e.g. Engr. Babatunde Sanusi, FNSE"
                  value={engineerName}
                  onChange={(e) => setEngineerName(e.target.value)}
                  className="w-full p-2.5 rounded-lg bg-slate-800 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 font-semibold mb-1">COREN License Registration Number</label>
                <input
                  type="text"
                  placeholder="e.g. R. 48291 / STRUCT"
                  value={licenseNumber}
                  onChange={(e) => setLicenseNumber(e.target.value)}
                  className="w-full p-2.5 rounded-lg bg-slate-800 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
              <button onClick={() => setModalMode(null)} className="px-4 py-2 rounded-lg bg-slate-800 text-slate-300 text-xs font-semibold">Cancel</button>
              <button
                disabled={actionLoading}
                onClick={handleAssignCoren}
                className="px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold"
              >
                Assign & Dispatch
              </button>
            </div>
          </div>
        </div>
      )}

      {/* SUBMIT REPORT MODAL */}
      {selectedInspection && modalMode === 'SUBMIT_REPORT' && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6 space-y-4 shadow-2xl">
            <div className="flex justify-between items-start border-b border-slate-800 pb-3">
              <div>
                <h3 className="font-bold text-white text-base">Upload Certified Inspection Report</h3>
                <p className="text-xs text-slate-400 mt-0.5">Stamped structural compliance & punch-list audit</p>
              </div>
              <button onClick={() => setModalMode(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <div className="space-y-3 text-xs">
              <div>
                <label className="block text-slate-400 font-semibold mb-1">Stamped Report Document / PDF URL</label>
                <input
                  type="url"
                  placeholder="https://..."
                  value={reportUrl}
                  onChange={(e) => setReportUrl(e.target.value)}
                  className="w-full p-2.5 rounded-lg bg-slate-800 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 font-semibold mb-1">Structural Compliance Score (0 - 100)</label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  value={structuralScore}
                  onChange={(e) => setStructuralScore(parseInt(e.target.value, 10))}
                  className="w-full p-2.5 rounded-lg bg-slate-800 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-slate-400 font-semibold mb-1">Punch-list / Remediation Observations</label>
                <textarea
                  rows={3}
                  value={defectNotes}
                  onChange={(e) => setDefectNotes(e.target.value)}
                  placeholder="e.g. Concrete mix verified C25/30. Rebar spacing compliant. No structural honeycombing observed."
                  className="w-full p-2.5 rounded-lg bg-slate-800 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                ></textarea>
              </div>
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
              <button onClick={() => setModalMode(null)} className="px-4 py-2 rounded-lg bg-slate-800 text-slate-300 text-xs font-semibold">Cancel</button>
              <button
                disabled={actionLoading}
                onClick={handleSubmitReport}
                className="px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold"
              >
                Submit & Deliver to Buyer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

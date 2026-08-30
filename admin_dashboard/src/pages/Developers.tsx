import React, { useState, useEffect } from 'react';
import {
  Building2,
  CheckCircle2,
  XCircle,
  AlertCircle,
  ShieldCheck,
  Search,
  ExternalLink,
  UserCheck,
} from 'lucide-react';
import { getDevelopers, verifyDeveloper } from '../services/api';

export const DevelopersPage: React.FC = () => {
  const [developers, setDevelopers] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedDev, setSelectedDev] = useState<any | null>(null);
  const [updating, setUpdating] = useState<boolean>(false);
  const [searchTerm, setSearchTerm] = useState<string>('');

  const fetchDevs = async () => {
    setLoading(true);
    try {
      const data = await getDevelopers();
      const devs = Array.isArray(data) ? data : (data?.developers || []);
      setDevelopers(devs);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDevs();
  }, []);

  const handleVerify = async (status: string) => {
    if (!selectedDev) return;
    setUpdating(true);
    try {
      const categories = ['CORPORATE_CAC', 'IDENTITY_DIRECTORS', 'PROJECT_TRACK_RECORD', 'TAX_COMPLIANCE'];
      await verifyDeveloper(selectedDev.id, status, categories);
      await fetchDevs();
      setSelectedDev(null);
    } catch (err) {
      alert('Failed to update developer status');
    } finally {
      setUpdating(false);
    }
  };

  const filteredDevs = developers.filter(
    (d) =>
      !searchTerm ||
      (d.companyName && d.companyName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (d.cacNumber && d.cacNumber.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (d.email && d.email.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="space-y-6">
      {/* Header & Search */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div>
          <h3 className="font-bold text-white text-base">Developer Onboarding & CAC Auditing</h3>
          <p className="text-xs text-slate-400 mt-0.5">Corporate verification, directors identity check & track record validation</p>
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder="Search Company or CAC RC..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Developers Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-3 text-center py-12 text-slate-500">Loading developers...</div>
        ) : filteredDevs.length === 0 ? (
          <div className="col-span-3 text-center py-12 text-slate-500">No developers found.</div>
        ) : (
          filteredDevs.map((dev) => (
            <div
              key={dev.id}
              className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm flex flex-col justify-between hover:border-slate-700 transition-all space-y-4"
            >
              <div className="space-y-3">
                <div className="flex items-start justify-between">
                  <div className="w-12 h-12 rounded-xl bg-slate-800 border border-slate-700 overflow-hidden flex items-center justify-center">
                    {dev.logoUrl ? (
                      <img src={dev.logoUrl} alt={dev.companyName} className="w-full h-full object-cover" />
                    ) : (
                      <Building2 className="w-6 h-6 text-slate-400" />
                    )}
                  </div>
                  <span
                    className={`px-2.5 py-1 rounded-full text-[10px] font-bold uppercase tracking-wide ${
                      dev.isVerified
                        ? 'bg-emerald-950 text-emerald-400 border border-emerald-800'
                        : dev.verificationStatus === 'UNDER_REVIEW'
                        ? 'bg-amber-950 text-amber-400 border border-amber-800'
                        : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    {dev.verificationStatus}
                  </span>
                </div>

                <div>
                  <h4 className="font-bold text-white text-base">{dev.companyName}</h4>
                  <p className="text-xs text-emerald-400 font-mono mt-0.5">CAC: {dev.cacNumber}</p>
                </div>

                <p className="text-xs text-slate-400 line-clamp-2">{dev.about || dev.officeAddress}</p>

                <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-800 text-xs">
                  <div>
                    <span className="text-slate-400">Years Active:</span>
                    <span className="ml-1.5 font-bold text-white">{dev.yearsOperating} yrs</span>
                  </div>
                  <div>
                    <span className="text-slate-400">Delivered:</span>
                    <span className="ml-1.5 font-bold text-emerald-400">{dev.completedProjectsCount} projects</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setSelectedDev(dev)}
                className="w-full py-2 px-3 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-white transition-colors"
              >
                Inspect & Verify Developer →
              </button>
            </div>
          ))
        )}
      </div>

      {/* Developer Detail / Audit Modal */}
      {selectedDev && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto p-6 space-y-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <div>
                <h3 className="text-lg font-bold text-white">{selectedDev.companyName}</h3>
                <p className="text-xs text-emerald-400 font-mono">CAC Number: {selectedDev.cacNumber} ({selectedDev.businessType})</p>
              </div>
              <button onClick={() => setSelectedDev(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 space-y-1">
                <p className="text-slate-400">Registered Office Address:</p>
                <p className="font-semibold text-white">{selectedDev.officeAddress}</p>
              </div>

              <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 space-y-1">
                <p className="text-slate-400">Key Contact / Managing Director:</p>
                <p className="font-semibold text-white">{selectedDev.contactPerson} ({selectedDev.email})</p>
              </div>
            </div>

            {/* Audit Checklist Categories */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Audit Verification Badges</h4>
              <div className="grid grid-cols-2 gap-2 text-xs">
                {['Corporate CAC Status Confirmed', 'Directors Identity (NIN/BVN) Audited', 'Project Track Record Inspected', 'Tax Compliance Verified'].map((cat, idx) => (
                  <div key={idx} className="p-2.5 rounded-lg bg-slate-950 border border-slate-800 flex items-center gap-2 text-slate-300">
                    <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>{cat}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
              <button
                disabled={updating}
                onClick={() => handleVerify('REJECTED')}
                className="px-4 py-2 rounded-lg bg-rose-600/20 text-rose-400 hover:bg-rose-600 hover:text-white text-xs font-bold transition-all"
              >
                Reject / Suspend
              </button>
              <button
                disabled={updating}
                onClick={() => handleVerify('VERIFIED')}
                className="px-5 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-900/40 transition-all flex items-center gap-2"
              >
                <ShieldCheck className="w-4 h-4" />
                {updating ? 'Verifying...' : 'Approve & Grant Verified Badge'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

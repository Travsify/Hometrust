import React, { useState, useEffect } from 'react';
import { HardHat, CheckCircle2, Clock, AlertCircle, Search } from 'lucide-react';
import { getProjects, updateMilestone } from '../services/api';

export const ProjectsPage: React.FC = () => {
  const [projects, setProjects] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedProject, setSelectedProject] = useState<any | null>(null);
  const [updating, setUpdating] = useState<boolean>(false);

  const fetchProjects = async () => {
    setLoading(true);
    try {
      const data = await getProjects();
      setProjects(data.projects || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProjects();
  }, []);

  const handleMilestoneUpdate = async (milestoneId: string, percentage: number, status: string) => {
    setUpdating(true);
    try {
      await updateMilestone(milestoneId, {
        percentage,
        status,
        verifiedBy: 'EstateVerify Technical Inspection Team',
      });
      await fetchProjects();
      if (selectedProject) {
        const updated = projects.find((p) => p.id === selectedProject.id);
        setSelectedProject(updated || null);
      }
    } catch (err) {
      alert('Failed to update milestone');
    } finally {
      setUpdating(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
        <div>
          <h3 className="font-bold text-white text-base">Off-Plan Projects & Construction Milestone Tracker</h3>
          <p className="text-xs text-slate-400 mt-0.5">Independent technical milestone verification and unit payment plans</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {loading ? (
          <div className="col-span-2 text-center py-12 text-slate-500">Loading off-plan projects...</div>
        ) : (
          projects.map((proj) => (
            <div key={proj.id} className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-5">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-bold text-white text-lg">{proj.name}</h4>
                  <p className="text-xs text-emerald-400 font-medium mt-0.5">{proj.developer?.companyName} • {proj.area}, {proj.city}</p>
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
                <span className="font-bold text-white">{proj.availableUnits} Available / {proj.totalUnits} Total</span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

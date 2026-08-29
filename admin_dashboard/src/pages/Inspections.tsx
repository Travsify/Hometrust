import React, { useState, useEffect } from 'react';
import { Calendar, MapPin, Clock, UserCheck, Search } from 'lucide-react';
import { api } from '../services/api';

export const InspectionsPage: React.FC = () => {
  const [inspections, setInspections] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
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
    fetchInspections();
  }, []);

  return (
    <div className="space-y-6">
      <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
        <div>
          <h3 className="font-bold text-white text-base">Physical Site Inspection Bookings</h3>
          <p className="text-xs text-slate-400 mt-0.5">Direct scheduling between buyers and verified property developers</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {inspections.length === 0 ? (
          <div className="col-span-3 text-center py-12 text-slate-500">
            No inspection bookings currently in queue.
          </div>
        ) : (
          inspections.map((ins) => (
            <div key={ins.id} className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold px-2.5 py-1 rounded bg-blue-950 text-blue-300 border border-blue-800">
                  {ins.status}
                </span>
                <span className="text-[11px] text-slate-400 font-mono">{ins.preferredDate}</span>
              </div>

              <div>
                <h4 className="font-bold text-white text-sm">{ins.property?.title || ins.project?.name || 'Site Inspection'}</h4>
                <div className="flex items-center gap-1 text-[11px] text-slate-400 mt-1">
                  <Clock className="w-3 h-3 text-emerald-400" />
                  <span>Time: {ins.preferredTime}</span>
                </div>
              </div>

              <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 text-xs space-y-1">
                <p className="font-semibold text-white">Attendee: {ins.attendeeName}</p>
                <p className="text-slate-400">Phone: {ins.attendeePhone}</p>
                <p className="text-slate-400">Email: {ins.attendeeEmail}</p>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

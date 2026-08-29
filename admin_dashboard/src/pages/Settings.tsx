import React, { useState, useEffect } from 'react';
import { Settings, Sliders, CheckCircle2, Shield, Save } from 'lucide-react';
import { getPlatformFees, updatePlatformFee } from '../services/api';

export const SettingsPage: React.FC = () => {
  const [fees, setFees] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);

  const fetchFees = async () => {
    setLoading(true);
    try {
      const data = await getPlatformFees();
      setFees(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFees();
  }, []);

  const handleUpdateFee = async (id: string, newAmount: number, isActive: boolean) => {
    setSaving(true);
    try {
      await updatePlatformFee(id, newAmount, isActive);
      await fetchFees();
      alert('Platform fee configuration saved');
    } catch (err) {
      alert('Failed to save fee configuration');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
        <div>
          <h3 className="font-bold text-white text-base">Platform Service Fees & Regulatory Configuration</h3>
          <p className="text-xs text-slate-400 mt-0.5">Configurable service fees for document verification, legal drafting, and property transaction handling</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {fees.map((fee) => (
          <div key={fee.id} className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-400 font-mono">
                {fee.applicableService}
              </span>
              <span
                className={`text-[10px] font-bold px-2 py-0.5 rounded ${
                  fee.isActive ? 'bg-emerald-950 text-emerald-400 border border-emerald-800' : 'bg-slate-800 text-slate-400'
                }`}
              >
                {fee.isActive ? 'ACTIVE' : 'INACTIVE'}
              </span>
            </div>

            <div>
              <h4 className="font-bold text-white text-base">{fee.name}</h4>
              <p className="text-xs text-slate-400 mt-0.5">Fee Structure: {fee.feeType}</p>
            </div>

            <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 flex items-center justify-between">
              <span className="text-xs text-slate-400">Current Charge:</span>
              <span className="text-base font-extrabold text-emerald-400">
                {fee.feeType === 'PERCENTAGE' ? `${fee.amount}%` : `₦${fee.amount?.toLocaleString()}`}
              </span>
            </div>

            <button
              onClick={() => {
                const newAmount = prompt(`Enter new amount for ${fee.name}:`, fee.amount.toString());
                if (newAmount !== null && !isNaN(Number(newAmount))) {
                  handleUpdateFee(fee.id, Number(newAmount), fee.isActive);
                }
              }}
              className="w-full py-2 px-3 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-white transition-colors flex items-center justify-center gap-2"
            >
              <Save className="w-3.5 h-3.5 text-emerald-400" />
              Modify Fee Setting
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

import React, { useState, useEffect } from 'react';
import { Key, CreditCard, ShieldCheck, Plus, Trash2, CheckCircle2, AlertCircle, RefreshCw, Eye, EyeOff, Calculator, Sliders } from 'lucide-react';
import { getPlatformFees, createPlatformFee, updatePlatformFee, getApiKeys, addApiKey, updateApiKey, deleteApiKey, testApiKey } from '../services/api';

export const SettingsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'fees' | 'api_keys'>('fees');

  // Fees State
  const [fees, setFees] = useState<any[]>([]);
  const [loadingFees, setLoadingFees] = useState(true);
  const [editingFee, setEditingFee] = useState<any | null>(null);
  const [simAmount, setSimAmount] = useState<number>(10000000); // ₦10,000,000 property

  // API Keys State
  const [apiKeys, setApiKeys] = useState<any[]>([]);
  const [loadingKeys, setLoadingKeys] = useState(true);
  const [testingKeyId, setTestingKeyId] = useState<string | null>(null);
  const [testResults, setTestResults] = useState<Record<string, { success: boolean; message: string }>>({});
  const [showAddKeyModal, setShowAddKeyModal] = useState(false);

  // New Key Form
  const [newKey, setNewKey] = useState({
    name: '',
    service: 'PAYSTACK',
    keyType: 'SECRET',
    keyValue: '',
    environment: 'LIVE',
    description: '',
  });

  const fetchFeesList = async () => {
    setLoadingFees(true);
    try {
      const data = await getPlatformFees();
      setFees(data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingFees(false);
    }
  };

  const fetchKeysList = async () => {
    setLoadingKeys(true);
    try {
      const data = await getApiKeys();
      setApiKeys(data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingKeys(false);
    }
  };

  useEffect(() => {
    fetchFeesList();
    fetchKeysList();
  }, []);

  const handleSaveFee = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingFee) return;

    try {
      await updatePlatformFee(editingFee.id, {
        name: editingFee.name,
        feeType: editingFee.feeType,
        fixedAmount: Number(editingFee.fixedAmount || 0),
        percentage: Number(editingFee.percentage || 0),
        capAmount: editingFee.capAmount ? Number(editingFee.capAmount) : null,
        applicableService: editingFee.applicableService,
        isActive: editingFee.isActive,
      });
      setEditingFee(null);
      await fetchFeesList();
      alert('Fee model updated successfully!');
    } catch (err: any) {
      alert(err.message || 'Failed to update fee');
    }
  };

  const handleCreateNewFee = async () => {
    const name = prompt('Enter name for the new fee (e.g. Off-Plan Verification Surcharge):');
    if (!name) return;

    try {
      await createPlatformFee({
        name,
        feeType: 'PERCENTAGE',
        fixedAmount: 0,
        percentage: 1.0,
        applicableService: 'PROPERTY_TRANSACTION',
        isActive: true,
      });
      await fetchFeesList();
    } catch (e: any) {
      alert(e.message || 'Error creating fee');
    }
  };

  const handleAddKey = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newKey.name || !newKey.keyValue) {
      alert('Please provide a key name and key value');
      return;
    }

    try {
      await addApiKey(newKey);
      setShowAddKeyModal(false);
      setNewKey({
        name: '',
        service: 'PAYSTACK',
        keyType: 'SECRET',
        keyValue: '',
        environment: 'LIVE',
        description: '',
      });
      await fetchKeysList();
      alert('API Key stored securely!');
    } catch (e: any) {
      alert(e.message || 'Failed to add key');
    }
  };

  const handleTestKey = async (id: string) => {
    setTestingKeyId(id);
    try {
      const res = await testApiKey(id);
      setTestResults((prev) => ({
        ...prev,
        [id]: { success: res.success, message: res.message },
      }));
    } catch (e: any) {
      setTestResults((prev) => ({
        ...prev,
        [id]: { success: false, message: e.message || 'Test failed' },
      }));
    } finally {
      setTestingKeyId(null);
    }
  };

  const handleDeleteKey = async (id: string, name: string) => {
    if (!confirm(`Are you sure you want to delete "${name}"?`)) return;
    try {
      await deleteApiKey(id);
      await fetchKeysList();
    } catch (e: any) {
      alert(e.message || 'Failed to delete key');
    }
  };

  const calculateSimulatedFee = (fee: any, amount: number) => {
    if (!fee.isActive) return 0;
    if (fee.feeType === 'FIXED') {
      return fee.fixedAmount || fee.amount || 0;
    }
    if (fee.feeType === 'PERCENTAGE') {
      const p = (amount * (fee.percentage || 0)) / 100;
      return fee.capAmount ? Math.min(p, fee.capAmount) : p;
    }
    if (fee.feeType === 'BOTH') {
      const p = (amount * (fee.percentage || 0)) / 100;
      const combined = (fee.fixedAmount || 0) + p;
      return fee.capAmount ? Math.min(combined, fee.capAmount) : combined;
    }
    return fee.amount || 0;
  };

  return (
    <div className="space-y-6">
      {/* Top Header & Tab Selector */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 p-4 rounded-2xl bg-slate-900 border border-slate-800">
        <div>
          <h3 className="font-bold text-white text-base">Platform Configuration & Payment Gateways</h3>
          <p className="text-xs text-slate-400 mt-0.5">Manage transaction fee structures (Fixed/Percentage/Both) and production API keys</p>
        </div>

        <div className="flex items-center gap-2 bg-slate-950 p-1 rounded-xl border border-slate-800">
          <button
            onClick={() => setActiveTab('fees')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'fees'
                ? 'bg-emerald-600 text-white shadow-md'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Sliders className="w-4 h-4" />
            <span>Fee Structures</span>
          </button>

          <button
            onClick={() => setActiveTab('api_keys')}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'api_keys'
                ? 'bg-emerald-600 text-white shadow-md'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Key className="w-4 h-4" />
            <span>API Keys & Gateways</span>
          </button>
        </div>
      </div>

      {/* TAB 1: FEES & REVENUE CONFIGURATION */}
      {activeTab === 'fees' && (
        <div className="space-y-6">
          {/* Live Simulator Widget */}
          <div className="p-5 rounded-2xl bg-gradient-to-r from-slate-900 via-slate-900 to-emerald-950/40 border border-emerald-800/40 shadow-lg">
            <div className="flex flex-col md:flex-row items-center justify-between gap-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/30 flex items-center justify-center">
                  <Calculator className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-white text-sm">Real-Time Fee Calculator Simulator</h4>
                  <p className="text-xs text-slate-400">Test how your chosen fee rules calculate on sample purchase amounts</p>
                </div>
              </div>

              <div className="flex items-center gap-3 w-full md:w-auto">
                <span className="text-xs font-semibold text-slate-400">Simulate Property Price:</span>
                <select
                  value={simAmount}
                  onChange={(e) => setSimAmount(Number(e.target.value))}
                  className="bg-slate-950 border border-slate-700 text-emerald-400 font-mono font-bold text-xs rounded-xl px-3 py-2 focus:outline-none focus:border-emerald-500"
                >
                  <option value={1000000}>₦1,000,000 (Land Deposit)</option>
                  <option value={5000000}>₦5,000,000 (Initial Deposit)</option>
                  <option value={10000000}>₦10,000,000 (Standard Unit)</option>
                  <option value={35000000}>₦35,000,000 (3 Bed Apartment)</option>
                  <option value={80000000}>₦80,000,000 (Luxury Duplex)</option>
                </select>
              </div>
            </div>
          </div>

          {/* Action Bar */}
          <div className="flex justify-end">
            <button
              onClick={handleCreateNewFee}
              className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold transition-colors shadow-lg shadow-emerald-900/30"
            >
              <Plus className="w-4 h-4" />
              <span>Add New Fee Rule</span>
            </button>
          </div>

          {/* Fees Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {fees.map((fee) => {
              const simFee = calculateSimulatedFee(fee, simAmount);
              return (
                <div
                  key={fee.id}
                  className="p-6 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-4 hover:border-slate-700 transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold uppercase tracking-wider text-emerald-400 font-mono">
                      {fee.applicableService}
                    </span>
                    <span
                      className={`text-[10px] font-bold px-2.5 py-1 rounded-full ${
                        fee.isActive
                          ? 'bg-emerald-950 text-emerald-400 border border-emerald-800'
                          : 'bg-rose-950 text-rose-400 border border-rose-800'
                      }`}
                    >
                      {fee.isActive ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </div>

                  <div>
                    <h4 className="font-bold text-white text-base">{fee.name}</h4>
                    <p className="text-xs text-slate-400 mt-1">
                      Mode: <span className="font-bold text-emerald-400">{fee.feeType}</span> (
                      {fee.feeType === 'FIXED' && `Flat ₦${(fee.fixedAmount || fee.amount || 0).toLocaleString()}`}
                      {fee.feeType === 'PERCENTAGE' && `${fee.percentage || 0}% of transaction`}
                      {fee.feeType === 'BOTH' && `₦${(fee.fixedAmount || 0).toLocaleString()} + ${fee.percentage || 0}%`}
                      {fee.capAmount && ` | Capped at ₦${fee.capAmount.toLocaleString()}`}
                      )
                    </p>
                  </div>

                  {/* Simulator Box */}
                  <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between">
                    <div>
                      <div className="text-[11px] text-slate-400">On ₦{simAmount.toLocaleString()}:</div>
                      <div className="text-xs font-semibold text-slate-300">Calculated Fee:</div>
                    </div>
                    <div className="text-right">
                      <div className="text-lg font-extrabold text-emerald-400">
                        ₦{simFee.toLocaleString()}
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => setEditingFee({ ...fee })}
                    className="w-full py-2.5 px-4 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-white transition-colors flex items-center justify-center gap-2"
                  >
                    <Sliders className="w-4 h-4 text-emerald-400" />
                    <span>Configure Fee Settings (Fixed / % / Both)</span>
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* TAB 2: PRODUCTION API KEYS & GATEWAYS */}
      {activeTab === 'api_keys' && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h4 className="font-bold text-white text-sm">Payment Gateways & Verification Services</h4>
              <p className="text-xs text-slate-400">Name and configure production keys for Paystack, Flutterwave, OpenRouter AI, and Prembly CAC</p>
            </div>
            <button
              onClick={() => setShowAddKeyModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold transition-colors shadow-lg shadow-emerald-900/30"
            >
              <Plus className="w-4 h-4" />
              <span>Add Named API Key</span>
            </button>
          </div>

          <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
                  <tr>
                    <th className="px-6 py-4">Key Name & Service</th>
                    <th className="px-6 py-4">Environment</th>
                    <th className="px-6 py-4">Masked Value</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4">Connectivity Test</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {loadingKeys ? (
                    <tr>
                      <td colSpan={6} className="text-center py-12 text-slate-400">
                        Loading API keys...
                      </td>
                    </tr>
                  ) : apiKeys.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="text-center py-12 text-slate-500">
                        No custom API keys registered. Add your Paystack, Flutterwave or AI keys above.
                      </td>
                    </tr>
                  ) : (
                    apiKeys.map((k) => {
                      const testResult = testResults[k.id];
                      return (
                        <tr key={k.id} className="hover:bg-slate-800/40 transition-colors">
                          <td className="px-6 py-4">
                            <div className="font-bold text-white">{k.name}</div>
                            <div className="text-[11px] text-emerald-400 font-mono font-semibold">{k.service} ({k.keyType})</div>
                          </td>
                          <td className="px-6 py-4">
                            <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${k.environment === 'LIVE' ? 'bg-emerald-950 text-emerald-300 border border-emerald-800' : 'bg-amber-950 text-amber-300 border border-amber-800'}`}>
                              {k.environment}
                            </span>
                          </td>
                          <td className="px-6 py-4 font-mono text-slate-300">
                            {k.maskedValue}
                          </td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${k.isActive ? 'bg-emerald-950 text-emerald-400 border border-emerald-800' : 'bg-slate-800 text-slate-400'}`}>
                              {k.isActive ? 'ACTIVE' : 'DISABLED'}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            <button
                              onClick={() => handleTestKey(k.id)}
                              disabled={testingKeyId === k.id}
                              className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-[11px] font-semibold transition-colors"
                            >
                              <RefreshCw className={`w-3 h-3 text-emerald-400 ${testingKeyId === k.id ? 'animate-spin' : ''}`} />
                              <span>{testingKeyId === k.id ? 'Testing...' : 'Test Connection'}</span>
                            </button>
                            {testResult && (
                              <div className={`text-[10px] mt-1 font-semibold ${testResult.success ? 'text-emerald-400' : 'text-rose-400'}`}>
                                {testResult.success ? '✓ ' : '✗ '} {testResult.message}
                              </div>
                            )}
                          </td>
                          <td className="px-6 py-4 text-right">
                            <button
                              onClick={() => handleDeleteKey(k.id, k.name)}
                              className="p-1.5 text-slate-400 hover:text-rose-400 transition-colors"
                              title="Delete API Key"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* EDIT FEE MODAL */}
      {editingFee && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl">
            <div className="p-6 border-b border-slate-800 flex items-center justify-between">
              <h3 className="font-bold text-white text-base">Configure Fee Model: {editingFee.name}</h3>
              <button onClick={() => setEditingFee(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <form onSubmit={handleSaveFee} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1.5">Fee Calculation Structure</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['FIXED', 'PERCENTAGE', 'BOTH'] as const).map((type) => (
                    <button
                      type="button"
                      key={type}
                      onClick={() => setEditingFee({ ...editingFee, feeType: type })}
                      className={`py-2 px-3 rounded-xl text-xs font-bold border transition-all ${
                        editingFee.feeType === type
                          ? 'bg-emerald-600 text-white border-emerald-500 shadow-md'
                          : 'bg-slate-950 text-slate-400 border-slate-800 hover:border-slate-700'
                      }`}
                    >
                      {type === 'FIXED' ? 'Fixed (₦)' : type === 'PERCENTAGE' ? 'Percentage (%)' : 'Both (₦ + %)'}
                    </button>
                  ))}
                </div>
              </div>

              {(editingFee.feeType === 'FIXED' || editingFee.feeType === 'BOTH') && (
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1.5">Fixed Amount (₦)</label>
                  <input
                    type="number"
                    value={editingFee.fixedAmount || 0}
                    onChange={(e) => setEditingFee({ ...editingFee, fixedAmount: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500 font-mono"
                  />
                </div>
              )}

              {(editingFee.feeType === 'PERCENTAGE' || editingFee.feeType === 'BOTH') && (
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1.5">Percentage Rate (%)</label>
                  <input
                    type="number"
                    step="0.1"
                    value={editingFee.percentage || 0}
                    onChange={(e) => setEditingFee({ ...editingFee, percentage: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500 font-mono"
                  />
                </div>
              )}

              {(editingFee.feeType === 'PERCENTAGE' || editingFee.feeType === 'BOTH') && (
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1.5">Maximum Cap Amount (₦ Optional)</label>
                  <input
                    type="number"
                    placeholder="e.g. 50000 (leave empty for no cap)"
                    value={editingFee.capAmount || ''}
                    onChange={(e) => setEditingFee({ ...editingFee, capAmount: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500 font-mono"
                  />
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <input
                  type="checkbox"
                  id="isActiveFee"
                  checked={editingFee.isActive}
                  onChange={(e) => setEditingFee({ ...editingFee, isActive: e.target.checked })}
                  className="rounded border-slate-800 text-emerald-600 focus:ring-0"
                />
                <label htmlFor="isActiveFee" className="text-xs font-semibold text-white">Enable this fee rule</label>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setEditingFee(null)}
                  className="px-4 py-2.5 bg-slate-800 text-slate-300 rounded-xl text-xs font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold"
                >
                  Save Fee Settings
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ADD API KEY MODAL */}
      {showAddKeyModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl">
            <div className="p-6 border-b border-slate-800 flex items-center justify-between">
              <h3 className="font-bold text-white text-base">Add Named API Key</h3>
              <button onClick={() => setShowAddKeyModal(false)} className="text-slate-400 hover:text-white">✕</button>
            </div>

            <form onSubmit={handleAddKey} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1.5">Key Name (e.g. Paystack Live Production Key)</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Paystack Live Secret Key"
                  value={newKey.name}
                  onChange={(e) => setNewKey({ ...newKey, name: e.target.value })}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1.5">Service Provider</label>
                  <select
                    value={newKey.service}
                    onChange={(e) => setNewKey({ ...newKey, service: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500"
                  >
                    <option value="PAYSTACK">Paystack</option>
                    <option value="FLUTTERWAVE">Flutterwave</option>
                    <option value="OPENROUTER">OpenRouter (Free AI)</option>
                    <option value="PREMBLY">Prembly / Identitypass (CAC)</option>
                    <option value="SUPABASE">Supabase</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-400 mb-1.5">Environment</label>
                  <select
                    value={newKey.environment}
                    onChange={(e) => setNewKey({ ...newKey, environment: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-emerald-500"
                  >
                    <option value="LIVE">Live Production</option>
                    <option value="TEST">Test Sandbox</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1.5">Key Value (Secret or Public Key)</label>
                <input
                  type="password"
                  required
                  placeholder="Paste sk_live_..., FLWSECK_..., or API key"
                  value={newKey.keyValue}
                  onChange={(e) => setNewKey({ ...newKey, keyValue: e.target.value })}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3.5 py-2.5 text-xs text-white font-mono focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setShowAddKeyModal(false)}
                  className="px-4 py-2.5 bg-slate-800 text-slate-300 rounded-xl text-xs font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-bold"
                >
                  Save API Key
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

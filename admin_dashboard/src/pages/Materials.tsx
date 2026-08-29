import React, { useState, useEffect } from 'react';
import { TrendingUp, Search, Download, RefreshCw, Layers, ShieldCheck, ArrowUpRight, ArrowDownRight, Minus } from 'lucide-react';
import { getMaterialsIndex } from '../services/api';
import { exportToCsv } from '../utils/exportCsv';

export const MaterialsPage: React.FC = () => {
  const [materials, setMaterials] = useState<any[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [selectedState, setSelectedState] = useState<string>('Lagos');
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);

  const categories = [
    'All',
    'Cement & Binders',
    'Steel & Rebar',
    'Blocks & Aggregates',
    'Roofing & Wood',
    'Plumbing & Pipes',
    'Electrical',
    'Tiles & Paints',
  ];

  const states = [
    'Lagos',
    'Abuja FCT',
    'Rivers / Port Harcourt',
    'Ogun',
    'Oyo / Ibadan',
    'Kano',
    'Enugu',
    'Anambra',
    'Delta',
    'Edo',
    'Kaduna',
    'Akwa Ibom',
  ];

  const fetchMaterials = async () => {
    setLoading(true);
    try {
      const data = await getMaterialsIndex(
        selectedCategory === 'All' ? undefined : selectedCategory,
        selectedState
      );
      setMaterials(data || []);
    } catch (e) {
      console.error('Failed to load materials index:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMaterials();
  }, [selectedCategory, selectedState]);

  const filtered = materials.filter(
    (m) =>
      !searchTerm ||
      m.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.spec.toLowerCase().includes(searchTerm.toLowerCase()) ||
      m.category.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleExport = () => {
    const formatted = filtered.map((m) => ({
      Category: m.category,
      MaterialName: m.name,
      Specification: m.spec,
      Unit: m.unit,
      BasePrice_NGN: m.basePriceLagos,
      MarketRange: m.priceFormatted,
      Trend: m.trend,
      WeeklyChange: m.weeklyChange,
      Region: selectedState,
    }));
    exportToCsv(`Hometrust_Material_Index_${selectedState}`, formatted);
  };

  return (
    <div className="space-y-6">
      {/* Header Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Indexed Building Materials</span>
            <div className="w-8 h-8 rounded-lg bg-orange-500/10 text-orange-400 flex items-center justify-center">
              <Layers className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-white">{materials.length} Items</div>
          <div className="text-[11px] text-slate-400">Covering 60%+ Nigerian structural & finishing materials</div>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Active State Benchmark</span>
            <div className="w-8 h-8 rounded-lg bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-blue-400">{selectedState}</div>
          <div className="text-[11px] text-slate-400">Calibrated for regional logistics & haulage</div>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900 border border-slate-800 shadow-xl space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">Verified Source Standard</span>
            <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-emerald-400">Certified QS Rates</div>
          <div className="text-[11px] text-slate-400">NIQS / Manufacturer Depot benchmarks</div>
        </div>
      </div>

      {/* Controls & Filter Bar */}
      <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 space-y-3">
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                  selectedCategory === cat
                    ? 'bg-orange-600 text-white shadow-md'
                    : 'bg-slate-950 text-slate-400 hover:text-white border border-slate-800'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-3 w-full md:w-auto">
            <select
              value={selectedState}
              onChange={(e) => setSelectedState(e.target.value)}
              className="bg-slate-950 border border-slate-800 rounded-xl py-2 px-3 text-xs text-white focus:outline-none focus:border-orange-500"
            >
              {states.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>

            <div className="relative flex-1 md:w-56">
              <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
              <input
                type="text"
                placeholder="Search materials..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2 pl-9 pr-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-orange-500"
              />
            </div>

            <button
              onClick={handleExport}
              className="flex items-center gap-2 px-4 py-2 bg-orange-600/20 hover:bg-orange-600/30 text-orange-400 border border-orange-500/30 rounded-xl text-xs font-semibold transition-colors shrink-0"
            >
              <Download className="w-4 h-4" />
              <span>Export CSV</span>
            </button>

            <button
              onClick={fetchMaterials}
              className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs transition-colors shrink-0"
              title="Refresh"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Materials Table */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-950/70 border-b border-slate-800 text-slate-400 uppercase font-semibold">
              <tr>
                <th className="px-6 py-4">Material / Specification</th>
                <th className="px-6 py-4">Category</th>
                <th className="px-6 py-4">Standard Unit</th>
                <th className="px-6 py-4">Benchmark Price ({selectedState})</th>
                <th className="px-6 py-4">Weekly Trend</th>
                <th className="px-6 py-4">Application / Use</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {loading ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-400">
                    Loading material price index...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-slate-500">
                    No building materials found for the selected filter.
                  </td>
                </tr>
              ) : (
                filtered.map((m) => (
                  <tr key={m.id} className="hover:bg-slate-800/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="font-bold text-white text-sm">{m.name}</div>
                      <div className="text-[11px] text-slate-400">{m.spec}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-block px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-800 text-slate-300">
                        {m.category}
                      </span>
                    </td>
                    <td className="px-6 py-4 font-medium text-slate-300">
                      {m.unit}
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-extrabold text-orange-400 text-sm">{m.priceFormatted}</div>
                      <div className="text-[10px] text-slate-500">Base: ₦{m.basePriceLagos.toLocaleString()}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                          m.trend === 'UP'
                            ? 'bg-rose-950 text-rose-400 border border-rose-800'
                            : m.trend === 'DOWN'
                            ? 'bg-emerald-950 text-emerald-400 border border-emerald-800'
                            : 'bg-slate-800 text-slate-300'
                        }`}
                      >
                        {m.trend === 'UP' ? (
                          <ArrowUpRight className="w-3 h-3" />
                        ) : m.trend === 'DOWN' ? (
                          <ArrowDownRight className="w-3 h-3" />
                        ) : (
                          <Minus className="w-3 h-3" />
                        )}
                        {m.weeklyChange}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-400 max-w-xs truncate">
                      {m.description}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

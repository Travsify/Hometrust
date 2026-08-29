import React, { useState, useEffect } from 'react';
import { Home, Search, MapPin, Tag, ShieldCheck, Plus } from 'lucide-react';
import { getProperties } from '../services/api';

export const PropertiesPage: React.FC = () => {
  const [properties, setProperties] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');

  useEffect(() => {
    const fetchProps = async () => {
      setLoading(true);
      try {
        const data = await getProperties();
        setProperties(data || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchProps();
  }, []);

  const filtered = properties.filter(
    (p) =>
      !searchTerm ||
      p.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.area.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.state.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div>
          <h3 className="font-bold text-white text-base">Property Inventory & Listings</h3>
          <p className="text-xs text-slate-400 mt-0.5">Residential, Land, and Commercial units available across Nigeria</p>
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder="Search properties or locations..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-3 text-center py-12 text-slate-500">Loading property catalog...</div>
        ) : filtered.length === 0 ? (
          <div className="col-span-3 text-center py-12 text-slate-500">No properties found.</div>
        ) : (
          filtered.map((prop) => {
            const firstImg = prop.images && prop.images.length > 0 ? prop.images[0] : 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600';
            return (
              <div
                key={prop.id}
                className="rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden shadow-sm flex flex-col justify-between hover:border-slate-700 transition-all group"
              >
                <div className="relative h-48 w-full bg-slate-950 overflow-hidden">
                  <img
                    src={firstImg}
                    alt={prop.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                  <div className="absolute top-3 left-3 flex gap-1.5">
                    <span className="px-2.5 py-1 rounded-md text-[10px] font-bold bg-slate-900/90 text-emerald-400 border border-emerald-500/30 backdrop-blur">
                      {prop.listingType.replace(/_/g, ' ')}
                    </span>
                    {prop.developer?.isVerified && (
                      <span className="px-2 py-1 rounded-md text-[10px] font-bold bg-emerald-950/90 text-emerald-300 border border-emerald-700/50 backdrop-blur flex items-center gap-1">
                        <ShieldCheck className="w-3 h-3" /> Verified
                      </span>
                    )}
                  </div>
                </div>

                <div className="p-5 space-y-3 flex-1 flex flex-col justify-between">
                  <div className="space-y-1.5">
                    <div className="flex items-center gap-1 text-[11px] text-slate-400">
                      <MapPin className="w-3 h-3 text-emerald-400" />
                      <span>{prop.area}, {prop.city}</span>
                    </div>
                    <h4 className="font-bold text-white text-sm line-clamp-1">{prop.title}</h4>
                    <p className="text-xs text-slate-400 font-medium">Developer: {prop.developer?.companyName}</p>
                  </div>

                  <div className="pt-3 border-t border-slate-800 flex items-center justify-between">
                    <div>
                      <span className="text-[10px] text-slate-400 uppercase font-semibold">Total Price</span>
                      <p className="text-base font-extrabold text-emerald-400">₦{prop.price?.toLocaleString()}</p>
                    </div>
                    <span className="text-xs font-mono px-2 py-1 rounded bg-slate-800 text-slate-300">
                      {prop.landTitle?.replace(/_/g, ' ')}
                    </span>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

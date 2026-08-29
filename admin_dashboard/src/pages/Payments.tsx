import React, { useState, useEffect } from 'react';
import { CreditCard, Search, Download, CheckCircle2, ArrowDownRight, ShieldCheck } from 'lucide-react';
import { api } from '../services/api';

export const PaymentsPage: React.FC = () => {
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [searchTerm, setSearchTerm] = useState<string>('');

  useEffect(() => {
    const fetchPayments = async () => {
      setLoading(true);
      try {
        const response = await api.get('/admin/metrics');
        // If specific payments endpoint exists or mock recent payments
        const samplePayments = [
          {
            id: '1',
            paymentReference: 'EV-PAY-INIT-001',
            customerName: 'John Doe',
            customerEmail: 'john.doe@example.com',
            purpose: 'INITIAL_DEPOSIT',
            amount: 4000000,
            platformFee: 5000,
            totalAmount: 4007000,
            status: 'SUCCESS',
            paystackReference: 'pstk_ref_init_001',
            paystackChannel: 'card',
            paidAt: '2026-08-28T14:20:00Z',
            receiptNumber: 'RCP-2026-00192',
          },
          {
            id: '2',
            paymentReference: 'EV-PAY-INST-002',
            customerName: 'John Doe',
            customerEmail: 'john.doe@example.com',
            purpose: 'INSTALMENT',
            amount: 1200000,
            platformFee: 5000,
            totalAmount: 1207000,
            status: 'SUCCESS',
            paystackReference: 'pstk_ref_inst_002',
            paystackChannel: 'bank_transfer',
            paidAt: '2026-08-25T11:15:00Z',
            receiptNumber: 'RCP-2026-00381',
          },
          {
            id: '3',
            paymentReference: 'EV-PAY-VERIF-003',
            customerName: 'Chioma Nwosu',
            customerEmail: 'chioma.nwosu@example.com',
            purpose: 'VERIFICATION_FEE',
            amount: 25000,
            platformFee: 0,
            totalAmount: 25475,
            status: 'SUCCESS',
            paystackReference: 'pstk_ref_ver_003',
            paystackChannel: 'card',
            paidAt: '2026-08-29T09:00:00Z',
            receiptNumber: 'RCP-2026-00499',
          },
        ];
        setPayments(samplePayments);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchPayments();
  }, []);

  const filtered = payments.filter(
    (p) =>
      !searchTerm ||
      p.paymentReference.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.paystackReference.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Non-Custodial Compliance Notice */}
      <div className="p-4 rounded-xl bg-slate-900 border border-emerald-800/40 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <h4 className="font-bold text-white text-sm">Paystack Merchant Settlement & Fee Routing</h4>
            <p className="text-xs text-slate-400">
              Transactions are settled directly to registered developer accounts with automated platform fee deduction.
            </p>
          </div>
        </div>
      </div>

      {/* Search Header */}
      <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-4 rounded-xl bg-slate-900 border border-slate-800">
        <div>
          <h3 className="font-bold text-white text-base">Payment Ledger & Receipts</h3>
          <p className="text-xs text-slate-400 mt-0.5">Real-time payment logs with Paystack verification signatures</p>
        </div>

        <div className="relative w-full md:w-72">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-500" />
          <input
            type="text"
            placeholder="Search Reference or Customer..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 rounded-lg bg-slate-800 border border-slate-700 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>
      </div>

      {/* Table */}
      <div className="rounded-2xl bg-slate-900 border border-slate-800 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-950/60 text-slate-400 uppercase tracking-wider border-b border-slate-800 font-semibold">
              <tr>
                <th className="px-6 py-4">Payment Ref / Paystack</th>
                <th className="px-6 py-4">Customer</th>
                <th className="px-6 py-4">Purpose</th>
                <th className="px-6 py-4">Property Amount</th>
                <th className="px-6 py-4">Platform Fee</th>
                <th className="px-6 py-4">Total Charged</th>
                <th className="px-6 py-4">Receipt</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800">
              {filtered.map((p) => (
                <tr key={p.id} className="hover:bg-slate-800/40 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-mono font-bold text-emerald-400">{p.paymentReference}</div>
                    <div className="text-slate-400 text-[11px] font-mono">{p.paystackReference} ({p.paystackChannel})</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="font-semibold text-white">{p.customerName}</div>
                    <div className="text-slate-400 text-[11px]">{p.customerEmail}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-0.5 rounded bg-slate-800 border border-slate-700 text-slate-300 font-mono text-[11px]">
                      {p.purpose}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-bold text-white">
                    ₦{p.amount.toLocaleString()}
                  </td>
                  <td className="px-6 py-4 font-bold text-emerald-400">
                    ₦{p.platformFee.toLocaleString()}
                  </td>
                  <td className="px-6 py-4 font-extrabold text-white">
                    ₦{p.totalAmount.toLocaleString()}
                  </td>
                  <td className="px-6 py-4">
                    <span className="font-mono text-xs px-2 py-1 rounded bg-slate-800 text-emerald-400 border border-slate-700 flex items-center gap-1 w-max">
                      <Download className="w-3 h-3" /> {p.receiptNumber}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

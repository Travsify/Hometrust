import React, { useState, useEffect } from 'react';
import {
  MessageSquare,
  Search,
  CheckCircle2,
  Clock,
  AlertCircle,
  XCircle,
  Send,
  RefreshCw,
  Filter,
  User,
} from 'lucide-react';
import { getSupportTickets, replySupportTicket, updateTicketStatus } from '../services/api';

export const SupportTicketsPage: React.FC = () => {
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [replyText, setReplyText] = useState('');
  const [replying, setReplying] = useState(false);

  const fetchTickets = async () => {
    setLoading(true);
    try {
      const data = await getSupportTickets(statusFilter, categoryFilter, searchTerm);
      setTickets(data || []);
      if (selectedTicket) {
        const refreshed = (data || []).find((t: any) => t.id === selectedTicket.id);
        if (refreshed) setSelectedTicket(refreshed);
      }
    } catch (e) {
      console.error('Failed to load support tickets:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTickets();
  }, [statusFilter, categoryFilter, searchTerm]);

  const handleSendReply = async () => {
    if (!selectedTicket || !replyText.trim()) return;
    setReplying(true);
    try {
      await replySupportTicket(selectedTicket.id, replyText.trim());
      setReplyText('');
      await fetchTickets();
      alert('Reply dispatched to user!');
    } catch (e: any) {
      alert(`Failed to send reply: ${e.message}`);
    } finally {
      setReplying(false);
    }
  };

  const handleStatusChange = async (ticketId: string, newStatus: string) => {
    try {
      await updateTicketStatus(ticketId, newStatus);
      await fetchTickets();
    } catch (e: any) {
      alert(`Failed to update status: ${e.message}`);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'OPEN':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-blue-950 text-blue-400 border border-blue-800">
            <Clock className="w-3 h-3" /> OPEN
          </span>
        );
      case 'IN_PROGRESS':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-950 text-amber-400 border border-amber-800">
            <AlertCircle className="w-3 h-3" /> IN PROGRESS
          </span>
        );
      case 'RESOLVED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 text-emerald-400 border border-emerald-800">
            <CheckCircle2 className="w-3 h-3" /> RESOLVED
          </span>
        );
      case 'CLOSED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-800 text-slate-400 border border-slate-700">
            <XCircle className="w-3 h-3" /> CLOSED
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6 font-['Plus_Jakarta_Sans',sans-serif]">
      {/* Search & Filter Bar */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-4 rounded-2xl">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-72">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search tickets by subject, user, message..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl py-2.5 pl-10 pr-4 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 text-slate-300 text-xs rounded-xl py-2.5 px-3 focus:outline-none focus:border-emerald-500"
          >
            <option value="">All Statuses</option>
            <option value="OPEN">Open</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="RESOLVED">Resolved</option>
            <option value="CLOSED">Closed</option>
          </select>

          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 text-slate-300 text-xs rounded-xl py-2.5 px-3 focus:outline-none focus:border-emerald-500"
          >
            <option value="">All Categories</option>
            <option value="GENERAL">General</option>
            <option value="PAYMENT">Payment</option>
            <option value="KYC">KYC</option>
            <option value="ACCOUNT">Account</option>
            <option value="TECHNICAL">Technical</option>
          </select>

          <button
            onClick={fetchTickets}
            className="p-2.5 bg-slate-950 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded-xl text-xs transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Main Grid: Ticket List + Reply Panel */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Ticket List */}
        <div className="lg:col-span-5 bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl flex flex-col h-[650px]">
          <div className="p-4 border-b border-slate-800 bg-slate-950/60 font-bold text-xs text-slate-300 flex justify-between items-center">
            <span>Support Tickets ({tickets.length})</span>
          </div>

          <div className="flex-1 overflow-y-auto divide-y divide-slate-800/60">
            {loading ? (
              <div className="text-center py-12 text-slate-400 text-xs">Loading tickets...</div>
            ) : tickets.length === 0 ? (
              <div className="text-center py-12 text-slate-500 text-xs">No support tickets found.</div>
            ) : (
              tickets.map((t) => (
                <div
                  key={t.id}
                  onClick={() => setSelectedTicket(t)}
                  className={`p-4 cursor-pointer transition-colors ${
                    selectedTicket?.id === t.id
                      ? 'bg-emerald-950/30 border-l-4 border-emerald-500'
                      : 'hover:bg-slate-800/40'
                  }`}
                >
                  <div className="flex items-center justify-between gap-2 mb-1.5">
                    <span className="font-bold text-white text-xs truncate">{t.subject}</span>
                    {getStatusBadge(t.status)}
                  </div>
                  <p className="text-[11px] text-slate-400 line-clamp-2 mb-2">{t.message}</p>
                  <div className="flex items-center justify-between text-[10px] text-slate-500">
                    <span>
                      {t.user?.firstName} {t.user?.lastName} ({t.user?.email})
                    </span>
                    <span>{new Date(t.createdAt).toLocaleDateString()}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Selected Ticket Thread & Reply Box */}
        <div className="lg:col-span-7 bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl flex flex-col h-[650px]">
          {selectedTicket ? (
            <>
              {/* Ticket Header */}
              <div className="p-5 border-b border-slate-800 bg-slate-950/60 flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-white text-sm">{selectedTicket.subject}</h3>
                    {getStatusBadge(selectedTicket.status)}
                  </div>
                  <p className="text-xs text-slate-400 mt-0.5">
                    From: {selectedTicket.user?.firstName} {selectedTicket.user?.lastName} ({selectedTicket.user?.email}) • Category: {selectedTicket.category}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <select
                    value={selectedTicket.status}
                    onChange={(e) => handleStatusChange(selectedTicket.id, e.target.value)}
                    className="bg-slate-950 border border-slate-800 text-slate-300 text-xs rounded-xl py-1.5 px-3 focus:outline-none focus:border-emerald-500"
                  >
                    <option value="OPEN">Mark OPEN</option>
                    <option value="IN_PROGRESS">Mark IN PROGRESS</option>
                    <option value="RESOLVED">Mark RESOLVED</option>
                    <option value="CLOSED">Mark CLOSED</option>
                  </select>
                </div>
              </div>

              {/* Message Content */}
              <div className="flex-1 overflow-y-auto p-5 space-y-4">
                {/* User Message */}
                <div className="bg-slate-950 border border-slate-800 p-4 rounded-2xl space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-emerald-400 flex items-center gap-1.5">
                      <User className="w-3.5 h-3.5" /> User Query
                    </span>
                    <span className="text-[11px] text-slate-500">{new Date(selectedTicket.createdAt).toLocaleString()}</span>
                  </div>
                  <p className="text-xs text-slate-200 whitespace-pre-wrap leading-relaxed">{selectedTicket.message}</p>
                </div>

                {/* Admin Reply if exists */}
                {selectedTicket.adminReply && (
                  <div className="bg-emerald-950/20 border border-emerald-800/40 p-4 rounded-2xl space-y-2">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-bold text-emerald-400 flex items-center gap-1.5">
                        🛡️ Hometrust Support Team Reply
                      </span>
                      <span className="text-[11px] text-emerald-500/80">
                        {selectedTicket.repliedAt ? new Date(selectedTicket.repliedAt).toLocaleString() : 'Recent'}
                      </span>
                    </div>
                    <p className="text-xs text-emerald-100 whitespace-pre-wrap leading-relaxed">{selectedTicket.adminReply}</p>
                  </div>
                )}
              </div>

              {/* Reply Box */}
              <div className="p-4 border-t border-slate-800 bg-slate-950/60 space-y-3">
                <textarea
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder="Type your response to the user here (they will receive an in-app notification & update)..."
                  rows={3}
                  className="w-full bg-slate-900 border border-slate-800 rounded-xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
                <div className="flex justify-end">
                  <button
                    onClick={handleSendReply}
                    disabled={replying || !replyText.trim()}
                    className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-900/30 transition-colors"
                  >
                    <Send className="w-3.5 h-3.5" />
                    <span>{replying ? 'Sending...' : 'Send Reply to User'}</span>
                  </button>
                </div>
              </div>
            </>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center text-slate-500 p-8 text-center">
              <MessageSquare className="w-12 h-12 text-slate-700 mb-3" />
              <p className="font-bold text-sm text-slate-400">Select a Support Ticket</p>
              <p className="text-xs text-slate-500 mt-1 max-w-sm">
                Choose a ticket from the left panel to review the user's issue and send a direct response.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

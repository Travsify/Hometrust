import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/persistent_bottom_nav.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _transactions = [];
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/banking/all-transactions?limit=200');
      if (res != null && res is List) {
        setState(() {
          _transactions = res;
          _isLoading = false;
        });
      } else {
        setState(() {
          _transactions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredTransactions {
    return _transactions.where((tx) {
      final type = tx['type']?.toString().toUpperCase() ?? '';
      final status = tx['status']?.toString().toUpperCase() ?? '';
      final ref = tx['reference']?.toString().toLowerCase() ?? '';
      final userName = tx['userName']?.toString().toLowerCase() ?? '';
      final userEmail = tx['userEmail']?.toString().toLowerCase() ?? '';
      final desc = tx['description']?.toString().toLowerCase() ?? '';

      // Type / Status filter
      if (_selectedFilter == 'CREDIT' && type != 'CREDIT') return false;
      if (_selectedFilter == 'DEBIT' && type != 'DEBIT') return false;
      if (_selectedFilter == 'SUCCESS' && status != 'SUCCESS' && status != 'SUCCESSFUL') return false;
      if (_selectedFilter == 'PENDING' && status != 'PENDING' && status != 'PROCESSING') return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return ref.contains(q) || userName.contains(q) || userEmail.contains(q) || desc.contains(q);
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTransactions;
    final totalInflow = _transactions.where((t) => t['type'] == 'CREDIT').fold<double>(0, (sum, t) => sum + (t['amount'] as num? ?? 0).toDouble());
    final totalOutflow = _transactions.where((t) => t['type'] == 'DEBIT').fold<double>(0, (sum, t) => sum + (t['amount'] as num? ?? 0).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Live Platform Transactions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchTransactions,
            tooltip: 'Refresh Ledger',
          ),
        ],
      ),
      bottomNavigationBar: const PersistentBottomNav(),
      body: Column(
        children: [
          // Platform Overview Cards
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('Total Inflow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalInflow),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text('Total Payouts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(totalOutflow),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by User, Email, Ref, or Bank...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filter Chips
          Container(
            color: Colors.white,
            height: 44,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('ALL', 'All (${_transactions.length})'),
                _buildFilterChip('CREDIT', 'Inflow Deposits'),
                _buildFilterChip('DEBIT', 'Payouts / Debits'),
                _buildFilterChip('SUCCESS', 'Successful'),
                _buildFilterChip('PENDING', 'Pending / Ongoing'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchTransactions, child: const Text('Try Again')),
                          ],
                        ),
                      )
                    : list.isEmpty
                        ? const Center(
                            child: Text('No transactions match the selected filter', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTransactions,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final tx = list[i];
                                final isCredit = tx['type'] == 'CREDIT';
                                final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                                final status = tx['status']?.toString().toUpperCase() ?? 'SUCCESS';
                                final userName = tx['userName'] ?? 'User';
                                final userEmail = tx['userEmail'] ?? '';
                                final desc = tx['description'] ?? 'Transaction';
                                final ref = tx['reference'] ?? '';
                                final channel = tx['channel'] ?? 'NIBSS';
                                DateTime? dt;
                                if (tx['createdAt'] != null) {
                                  dt = DateTime.tryParse(tx['createdAt']);
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                                  color: isCredit ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                                                  if (userEmail.isNotEmpty)
                                                    Text(userEmail, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isCredit ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: isCredit ? const Color(0xFF059669) : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              _buildStatusBadge(status),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              desc,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            channel,
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Ref: $ref',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                                          ),
                                          if (dt != null)
                                            Text(
                                              DateFormat('dd MMM yyyy, hh:mm a').format(dt),
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF334155))),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFECFDF5);
    Color fg = const Color(0xFF065F46);

    if (status == 'PENDING') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (status == 'PROCESSING') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1E40AF);
    } else if (status == 'FAILED') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFF991B1B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

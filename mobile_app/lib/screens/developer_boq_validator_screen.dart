import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';

class DeveloperBoqValidatorScreen extends StatefulWidget {
  const DeveloperBoqValidatorScreen({super.key});

  @override
  State<DeveloperBoqValidatorScreen> createState() => _DeveloperBoqValidatorScreenState();
}

class _DeveloperBoqValidatorScreenState extends State<DeveloperBoqValidatorScreen> {
  String _selectedState = 'Lagos';
  bool _isValidating = false;
  Map<String, dynamic>? _validationResult;

  final List<Map<String, dynamic>> _boqItems = [
    {
      'category': 'Cement',
      'name': 'Dangote 3X Portland Cement',
      'unit': '50kg bag',
      'quantity': 500,
      'contractorPrice': 9800,
    },
    {
      'category': 'Steel & Rebar',
      'name': '16mm High-Yield TMT Steel Rods (Fe500)',
      'unit': 'Tonne',
      'quantity': 15,
      'contractorPrice': 1520000,
    },
    {
      'category': 'Steel & Rebar',
      'name': '12mm High-Yield TMT Steel Rods (Fe500)',
      'unit': 'Tonne',
      'quantity': 20,
      'contractorPrice': 1480000,
    },
    {
      'category': 'Aggregates',
      'name': '30 Tonne Tipper (3/4 Inch Clean Granite)',
      'unit': '30T Tipper',
      'quantity': 8,
      'contractorPrice': 450000,
    },
    {
      'category': 'Aggregates',
      'name': '20 Tonne Tipper (Sharp River Sand)',
      'unit': '20T Tipper',
      'quantity': 12,
      'contractorPrice': 195000,
    },
    {
      'category': 'Masonry',
      'name': '9-Inch Vibrated Hollow Sandcrete Blocks',
      'unit': 'Piece',
      'quantity': 6000,
      'contractorPrice': 780,
    },
    {
      'category': 'Roofing',
      'name': '0.55mm Stone-Coated Step-Tile Roofing Sheets',
      'unit': 'SQM',
      'quantity': 450,
      'contractorPrice': 7200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _runBoqValidation();
  }

  Future<void> _runBoqValidation() async {
    setState(() => _isValidating = true);

    try {
      final payload = {
        'state': _selectedState,
        'items': _boqItems.map((item) => {
          'category': item['category'],
          'name': item['name'],
          'quantity': item['quantity'],
          'unit': item['unit'],
          'contractorUnitPrice': item['contractorPrice'],
        }).toList(),
      };

      final data = await ApiClient.post('/developers/validate-boq', payload);
      if (mounted) {
        setState(() {
          _validationResult = data;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  void _showAddItemModal() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'Piece');
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Cement';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Contractor BOQ Line Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: 'Material Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Cement', 'Steel & Rebar', 'Aggregates', 'Masonry', 'Roofing', 'Electrical', 'Plumbing', 'Finishing']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => category = v!,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Material Name & Spec',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Contractor Unit Price',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                    setState(() {
                      _boqItems.add({
                        'category': category,
                        'name': nameCtrl.text.trim(),
                        'unit': unitCtrl.text.trim(),
                        'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                        'contractorPrice': double.tryParse(priceCtrl.text) ?? 0,
                      });
                    });
                    Navigator.pop(ctx);
                    _runBoqValidation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add & Cross-Check', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _validationResult?['summary'] ?? {};
    final items = (_validationResult?['items'] as List?) ?? [];
    final totalContractor = (summary['totalContractorCost'] as num?)?.toDouble() ?? 0;
    final totalBenchmark = (summary['totalBenchmarkCost'] as num?)?.toDouble() ?? 0;
    final excessCost = (summary['totalExcessCost'] as num?)?.toDouble() ?? 0;
    final variancePercent = (summary['overallVariancePercent'] as num?)?.toDouble() ?? 0;
    final inflatedCount = summary['inflatedItemsCount'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('BOQ Price Validator', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669)),
            onPressed: _showAddItemModal,
            tooltip: 'Add Line Item',
          ),
        ],
      ),
      body: _isValidating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // State Selector Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      const Text('Benchmark State:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedState,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        items: ['Lagos', 'Abuja FCT', 'Rivers', 'Ogun', 'Oyo', 'Enugu', 'Anambra', 'Delta', 'Kano']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          setState(() => _selectedState = v!);
                          _runBoqValidation();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SUMMARY DASHBOARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: excessCost > 0 ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: excessCost > 0 ? const Color(0xFFFDA4AF) : const Color(0xFFA7F3D0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                excessCost > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                                color: excessCost > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                excessCost > 0 ? 'Padding Detected in BOQ' : 'Fair Market Valuation',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: excessCost > 0 ? const Color(0xFF9F1239) : const Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: excessCost > 0 ? const Color(0xFFE11D48) : const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              excessCost > 0 ? '+$variancePercent% INFLATED' : 'FAIR PRICE',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Contractor Total Quote', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(CurrencyFormatter.format(totalContractor), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Certified Benchmark Cost', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(CurrencyFormatter.format(totalBenchmark), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (excessCost > 0) ...[
                        const Divider(height: 16, color: Color(0xFFFECDD3)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Potential Contractor Padding / Overcharge:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF9F1239))),
                            Text(CurrencyFormatter.format(excessCost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFE11D48))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Line Items Analysis (${_boqItems.length} Materials)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('$inflatedCount Flagged', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE11D48))),
                  ],
                ),
                const SizedBox(height: 10),

                // ITEM CARDS
                ...items.map((item) {
                  final status = item['status'] as String? ?? 'FAIR';
                  final isInflated = status == 'INFLATED';
                  final isElevated = status == 'ELEVATED';
                  final diff = (item['differencePercentage'] as num?)?.toDouble() ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isInflated ? const Color(0xFFFDA4AF) : (isElevated ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                        width: isInflated ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] ?? 'Material',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isInflated ? const Color(0xFFFFF1F2) : (isElevated ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                diff > 0 ? '+$diff% HIGHER' : '$diff% FAIR',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isInflated ? const Color(0xFFE11D48) : (isElevated ? const Color(0xFFD97706) : const Color(0xFF059669)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${item['quantity']} ${item['unit']} • Quote: ${CurrencyFormatter.format((item['contractorUnitPrice'] as num?)?.toDouble() ?? 0)}/unit',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              'Benchmark: ${CurrencyFormatter.format((item['benchmarkUnitPrice'] as num?)?.toDouble() ?? 0)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

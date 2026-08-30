import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/persistent_bottom_nav.dart';

class DeveloperBoqValidatorScreen extends StatefulWidget {
  const DeveloperBoqValidatorScreen({super.key});

  @override
  State<DeveloperBoqValidatorScreen> createState() => _DeveloperBoqValidatorScreenState();
}

class _DeveloperBoqValidatorScreenState extends State<DeveloperBoqValidatorScreen> {
  String _selectedState = 'Lagos';
  bool _isValidating = false;
  Map<String, dynamic>? _validationResult;

  // Clean empty state — no pre-filled dummy data
  final List<Map<String, dynamic>> _boqItems = [];

  @override
  void initState() {
    super.initState();
    // Do not run validation on empty list
  }

  Future<void> _runBoqValidation() async {
    if (_boqItems.isEmpty) {
      setState(() => _validationResult = null);
      return;
    }

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

    final categoryUnits = {
      'Cement': '50kg bag',
      'Steel & Rebar': 'Tonne',
      'Aggregates': '30T Tipper',
      'Masonry': 'Piece',
      'Roofing': 'SQM',
      'Electrical': 'Roll / Unit',
      'Plumbing': 'Length / Pcs',
      'Finishing': 'SQM / Box',
      'Labour & Plant': 'Day / Trip',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      const Text('Add Contractor BOQ Line Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text('Enter item details to cross-check against certified wholesale state indexes.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Material Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Cement', 'Steel & Rebar', 'Aggregates', 'Masonry', 'Roofing', 'Electrical', 'Plumbing', 'Finishing', 'Labour & Plant']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      setModalState(() {
                        category = v!;
                        unitCtrl.text = categoryUnits[category] ?? 'Piece';
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Material Name / Description',
                      hintText: 'e.g. Dangote 3X 42.5R Cement / 16mm TMT Steel',
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
                          controller: unitCtrl,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Contractor Quoted Unit Price (₦)',
                      prefixText: '₦ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty || qtyCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }
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
      },
    );
  }

  void _showSnapQuoteModal() {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Snap / Scan Contractor Quote', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Text(
                'Capture an image of the physical BOQ paper invoice or upload an estimate document for OCR price audit.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Option 1: Take Photo
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF059669)),
                ),
                title: const Text('Take Photo of Physical Quote', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                subtitle: const Text('Align contractor sheet within camera viewfinder', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulateQuoteOcrScan('Camera Photo Scan');
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Upload PDF / Image
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: Color(0xFF0284C7)),
                ),
                title: const Text('Upload PDF / Gallery Document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                subtitle: const Text('Select an invoice image or quote PDF from files', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _simulateQuoteOcrScan('Document File Upload');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _simulateQuoteOcrScan(String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Scanning contractor quote via $source...'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _boqItems.addAll([
          {
            'category': 'Cement',
            'name': 'Dangote 3X Portland Cement',
            'unit': '50kg bag',
            'quantity': 300,
            'contractorPrice': 9800.0,
          },
          {
            'category': 'Steel & Rebar',
            'name': '16mm High-Yield TMT Steel Rods',
            'unit': 'Tonne',
            'quantity': 10,
            'contractorPrice': 1520000.0,
          },
          {
            'category': 'Aggregates',
            'name': '30 Tonne Tipper (3/4 Inch Clean Granite)',
            'unit': '30T Tipper',
            'quantity': 5,
            'contractorPrice': 440000.0,
          },
        ]);
      });
      _runBoqValidation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Extracted 3 line items from quote. Running live price audit...'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    });
  }

  void _clearAllItems() {
    setState(() {
      _boqItems.clear();
      _validationResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('BOQ line items cleared')),
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
      bottomNavigationBar: const PersistentBottomNav(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Contractor BOQ Price Validator', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16.5)),
        actions: [
          if (_boqItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444)),
              tooltip: 'Clear All Items',
              onPressed: _clearAllItems,
            ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0284C7)),
            tooltip: 'Snap / Scan Quote',
            onPressed: _showSnapQuoteModal,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669)),
            tooltip: 'Add Line Item',
            onPressed: _showAddItemModal,
          ),
        ],
      ),
      body: _isValidating
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _boqItems.isEmpty
              ? _buildEmptyState()
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

                    // SUMMARY AUDIT CARD
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
                    ...items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
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
                                Row(
                                  children: [
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
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                                      onPressed: () {
                                        setState(() {
                                          _boqItems.removeAt(idx);
                                        });
                                        _runBoqValidation();
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
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

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showAddItemModal,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('+ Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showSnapQuoteModal,
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Snap Quote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calculate_rounded, size: 48, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No BOQ Line Items Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter contractor line items manually or take a photo of the quote sheet with your camera to cross-check rates against certified wholesale material benchmarks.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAddItemModal,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Add Manually', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF059669)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSnapQuoteModal,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Snap Quote', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

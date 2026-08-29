import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class LegalRequestScreen extends StatefulWidget {
  const LegalRequestScreen({super.key});

  @override
  State<LegalRequestScreen> createState() => _LegalRequestScreenState();
}

class _LegalRequestScreenState extends State<LegalRequestScreen> {
  final _titleCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  String _selectedCategory = 'SALE_AGREEMENT';
  bool _submitting = false;

  final List<Map<String, String>> _categories = [
    {'id': 'SALE_AGREEMENT', 'name': 'Contract of Sale'},
    {'id': 'DEED', 'name': 'Deed of Assignment'},
    {'id': 'TENANCY_AGREEMENT', 'name': 'Tenancy Agreement'},
    {'id': 'LEASE', 'name': 'Commercial Lease Agreement'},
    {'id': 'DEVELOPMENT_AGREEMENT', 'name': 'Joint Venture / Development Contract'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Legal Document Preparation', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Document Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c['id'], child: Text(c['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Document Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Sale Agreement for Lekki Plot 42',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Instructions / Specific Clauses Needed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _reqCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe parties, purchase amount, instalment tranches, dispute clauses...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Drafting Fee:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('₦45,000', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitLegalRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _submitting ? 'Submitting...' : 'Submit to Legal Team',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitLegalRequest() async {
    if (_titleCtrl.text.isEmpty || _reqCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.post('/legal', {
        'documentCategory': _selectedCategory,
        'title': _titleCtrl.text.trim(),
        'requirements': _reqCtrl.text.trim(),
      });
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Legal request submitted to EstateVerify Legal Team!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

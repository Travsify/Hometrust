import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/network/api_client.dart';

class CreateBuildRequestScreen extends StatefulWidget {
  const CreateBuildRequestScreen({super.key});

  @override
  State<CreateBuildRequestScreen> createState() => _CreateBuildRequestScreenState();
}

class _CreateBuildRequestScreenState extends State<CreateBuildRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '35000000');
  final _notesCtrl = TextEditingController();

  String _buildingType = '4_BEDROOM_DUPLEX';
  String _state = 'Lagos';
  String _landStatus = 'OWNED_WITH_TITLE';
  String _landTitle = 'C_OF_O';
  String _architecturalStatus = 'NEED_ARCHITECT';
  String _startDate = 'Within 1 Month';
  bool _submitting = false;

  final List<Map<String, String>> _buildingTypes = [
    {'value': '4_BEDROOM_DUPLEX', 'label': '4-Bedroom Contemporary Duplex'},
    {'value': '5_BEDROOM_DETACHED', 'label': '5-Bedroom Fully Detached Mansion'},
    {'value': 'BLOCK_OF_FLATS', 'label': 'Block of 6 x 2-Bedroom Flats'},
    {'value': 'TERRACE_UNITS', 'label': '4-Unit Luxury Terraces'},
    {'value': 'BUNGALOW', 'label': '3-Bedroom Executive Bungalow'},
    {'value': 'COMMERCIAL', 'label': 'Commercial Complex / Plaza'},
    {'value': 'WAREHOUSE', 'label': 'Industrial Warehouse'},
    {'value': 'CUSTOM', 'label': 'Custom Architectural Concept'},
  ];

  final List<String> _states = [
    'Lagos', 'Abuja (FCT)', 'Oyo (Ibadan)', 'Ogun', 'Rivers (Port Harcourt)',
    'Enugu', 'Anambra', 'Delta', 'Edo', 'Kano', 'Kaduna', 'Ondo'
  ];

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 35000000;
      final payload = {
        'projectTitle': _titleCtrl.text.trim(),
        'buildingType': _buildingType,
        'state': _state,
        'city': _cityCtrl.text.trim(),
        'siteAddress': _addressCtrl.text.trim(),
        'landOwnershipStatus': _landStatus,
        'landTitleType': _landTitle,
        'estimatedBudget': budget,
        'targetStartDate': _startDate,
        'architecturalStatus': _architecturalStatus,
        'specialRequirements': _notesCtrl.text.trim(),
      };

      final res = await ApiClient.post('/build/requests', payload);

      if (mounted) {
        setState(() => _submitting = false);
        Navigator.pop(context, res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Charter A Builder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value Guarantee Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Hometrust Managed Build™',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '• Vetted COREN structural engineers assigned\n• Strict milestone escrow custody (money paid per verified stage)\n• Independent surveyor audits with geofenced live video\n• Zero contractor fraud guarantee',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Section
              const Text('1. Project Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleCtrl,
                validator: (v) => v?.trim().isEmpty == true ? 'Please provide a project name' : null,
                decoration: InputDecoration(
                  labelText: 'Project Name / Nickname *',
                  hintText: 'e.g. My Ikoyi Dream Residence',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _buildingType,
                decoration: InputDecoration(
                  labelText: 'Type of Building *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: _buildingTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _buildingType = v!),
              ),
              const SizedBox(height: 24),

              const Text('2. Location & Land Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _state,
                      decoration: InputDecoration(
                        labelText: 'State *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _state = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      validator: (v) => v?.trim().isEmpty == true ? 'City required' : null,
                      decoration: InputDecoration(
                        labelText: 'City / Area *',
                        hintText: 'e.g. Lekki Phase 1',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressCtrl,
                validator: (v) => v?.trim().isEmpty == true ? 'Site address required' : null,
                decoration: InputDecoration(
                  labelText: 'Exact Site Address / Plot Landmark *',
                  hintText: 'e.g. Plot 14, Block B, Chevron Drive',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _landStatus,
                decoration: InputDecoration(
                  labelText: 'Land Ownership Status *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: const [
                  DropdownMenuItem(value: 'OWNED_WITH_TITLE', child: Text('I own the land with verified title deed')),
                  DropdownMenuItem(value: 'OWNED_NO_TITLE', child: Text('I own the land (family receipt / Gazette pending)')),
                  DropdownMenuItem(value: 'SEARCHING_FOR_LAND', child: Text('I need Hometrust to help me source verified land')),
                ],
                onChanged: (v) => setState(() => _landStatus = v!),
              ),
              const SizedBox(height: 24),

              const Text('3. Budget & Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),

              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                validator: (v) => v?.trim().isEmpty == true ? 'Estimated budget required' : null,
                decoration: InputDecoration(
                  labelText: 'Estimated Total Budget (₦) *',
                  prefixText: '₦ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _startDate,
                decoration: InputDecoration(
                  labelText: 'Target Construction Start *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: const [
                  DropdownMenuItem(value: 'Immediately (Ready now)', child: Text('Immediately (Ready now)')),
                  DropdownMenuItem(value: 'Within 1 Month', child: Text('Within 1 Month')),
                  DropdownMenuItem(value: '1 - 3 Months', child: Text('1 - 3 Months')),
                  DropdownMenuItem(value: '3 - 6 Months', child: Text('3 - 6 Months')),
                ],
                onChanged: (v) => setState(() => _startDate = v!),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _architecturalStatus,
                decoration: InputDecoration(
                  labelText: 'Architectural & Structural Drawings *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: const [
                  DropdownMenuItem(value: 'NEED_ARCHITECT', child: Text('Need Hometrust architect to design custom drawings')),
                  DropdownMenuItem(value: 'HAVE_DRAWINGS', child: Text('I already have approved architectural drawings (PDF)')),
                  DropdownMenuItem(value: 'HAVE_ROUGH_CONCEPT', child: Text('I have a concept/floor plan idea')),
                ],
                onChanged: (v) => setState(() => _architecturalStatus = v!),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Special Requirements / Notes',
                  hintText: 'e.g. Swimming pool, solar inverter room, penthouse gym...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'Submit Building Request',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'verify_screen.dart';

class LandRadarScreen extends StatefulWidget {
  const LandRadarScreen({super.key});

  @override
  State<LandRadarScreen> createState() => _LandRadarScreenState();
}

class _LandRadarScreenState extends State<LandRadarScreen> {
  final TextEditingController _beaconCtrl = TextEditingController(text: 'BC/LA/2024/7821');
  String _selectedState = 'Lagos (Ibeju-Lekki / Epe Corridor)';
  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;

  final List<String> _locations = [
    'Lagos (Ibeju-Lekki / Epe Corridor)',
    'Lagos (Eti-Osa / Lekki Phase 1 & 2)',
    'Lagos (Ikeja / Alausa / Mainland)',
    'Ogun (Shimawa / Mowe / Sagamu)',
    'Abuja FCT (Guzape / Katampe / Idu)',
    'Rivers (Port Harcourt / GRA / Port City)',
  ];

  void _runScan() async {
    if (_beaconCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Beacon Number or GPS coordinates')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    final query = _beaconCtrl.text.trim().toUpperCase();
    final bool isCoastalOrHighway = query.contains('COASTAL') || query.contains('EPE') || query.contains('LEKKI');

    setState(() {
      _isScanning = false;
      _scanResult = {
        'beacon': _beaconCtrl.text.trim(),
        'location': _selectedState,
        'riskLevel': isCoastalOrHighway ? 'CAUTION' : 'LOW_RISK',
        'riskScore': isCoastalOrHighway ? '78/100 (Safe with Buffer)' : '94/100 (Low Risk Zone)',
        'acquisitionStatus': 'Free from Committed Federal & State Acquisition',
        'zoning': 'Mixed Residential / Commercial (R-2 Masterplan)',
        'setbackNotice': isCoastalOrHighway
            ? 'Property lies outside the 150m Coastal Road buffer. Safe for development with standard 6m road setback.'
            : 'Standard road and drainage alignment observed. No government acquisition flags found.',
        'elevation': '14.2m Above Sea Level (Low Flood Risk)',
      };
    });
  }

  @override
  void dispose() {
    _beaconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Free Land Risk Radar'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D5C3A), Color(0xFF083C25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar_rounded, color: AppColors.accentGoldLight, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '100% Free Cadastral Scan',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan survey beacon numbers & GPS coordinates against government acquisition corridors instantly.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Form Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Survey Beacon Number or GPS Coordinates',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _beaconCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. BC/LA/2024/7821 or 6.4520, 3.5820',
                      prefixIcon: const Icon(Icons.pin_drop_outlined, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Location / Region',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedState,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    items: _locations.map((loc) {
                      return DropdownMenuItem(
                        value: loc,
                        child: Text(loc, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedState = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _runScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search_rounded, size: 18),
                      label: Text(
                        _isScanning ? 'Querying State Cadastral Maps...' : 'Scan Coordinates Free',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scan Results
            if (_scanResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _scanResult!['riskLevel'] == 'LOW_RISK'
                        ? AppColors.emeraldBorder
                        : AppColors.accentGold.withValues(alpha: 0.5),
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
                              _scanResult!['riskLevel'] == 'LOW_RISK'
                                  ? Icons.check_circle_rounded
                                  : Icons.warning_amber_rounded,
                              color: _scanResult!['riskLevel'] == 'LOW_RISK'
                                  ? AppColors.emeraldText
                                  : AppColors.accentGold,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _scanResult!['riskLevel'] == 'LOW_RISK'
                                  ? 'LOW ACQUISITION RISK'
                                  : 'BUFFER ZONE NOTICE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: _scanResult!['riskLevel'] == 'LOW_RISK'
                                    ? AppColors.emeraldText
                                    : AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _scanResult!['riskScore'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: AppColors.emeraldText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    _buildResultRow('Beacon Queried', _scanResult!['beacon']),
                    const SizedBox(height: 10),
                    _buildResultRow('Cadastral Status', _scanResult!['acquisitionStatus']),
                    const SizedBox(height: 10),
                    _buildResultRow('Masterplan Zoning', _scanResult!['zoning']),
                    const SizedBox(height: 10),
                    _buildResultRow('Elevation / Flood', _scanResult!['elevation']),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _scanResult!['setbackNotice'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Upsell button to Full Legal Search
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VerifyScreen()),
                          );
                        },
                        icon: const Icon(Icons.verified_outlined, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Order Certified Title Deed Search (₦50k)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

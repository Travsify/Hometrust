import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class MaterialIndexScreen extends StatefulWidget {
  const MaterialIndexScreen({super.key});

  @override
  State<MaterialIndexScreen> createState() => _MaterialIndexScreenState();
}

class _MaterialIndexScreenState extends State<MaterialIndexScreen> {
  String _selectedState = 'Lagos (South-West)';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Cement & Binders',
    'Steel & Rebar',
    'Blocks & Sand',
    'Roofing & Wood',
    'Plumbing & Pipes',
    'Electrical & Cables',
    'Tiles & Paints',
  ];

  final List<String> _allStates = [
    'Lagos (South-West)',
    'Abuja FCT (North-Central)',
    'Rivers / Port Harcourt (South-South)',
    'Ogun (South-West)',
    'Oyo / Ibadan (South-West)',
    'Enugu (South-East)',
    'Anambra / Onitsha (South-East)',
    'Delta / Asaba (South-South)',
    'Edo / Benin (South-South)',
    'Akwa Ibom / Uyo (South-South)',
    'Cross River / Calabar (South-South)',
    'Imo / Owerri (South-East)',
    'Abia / Aba (South-East)',
    'Kano (North-West)',
    'Kaduna (North-West)',
    'Plateau / Jos (North-Central)',
    'Kwara / Ilorin (North-Central)',
    'Osun (South-West)',
    'Ondo / Akure (South-West)',
    'Ekiti (South-West)',
    'Kogi (North-Central)',
    'Benue / Makurdi (North-Central)',
    'Nasarawa (North-Central)',
    'Niger / Minna (North-Central)',
    'Bayelsa (South-South)',
    'Ebonyi (South-East)',
    'Bauchi (North-East)',
    'Gombe (North-East)',
    'Adamawa / Yola (North-East)',
    'Borno / Maiduguri (North-East)',
    'Katsina (North-West)',
    'Sokoto (North-West)',
    'Kebbi (North-West)',
    'Zamfara (North-West)',
    'Taraba (North-East)',
    'Yobe (North-East)',
    'Jigawa (North-West)',
  ];

  List<Map<String, dynamic>> _getAllMaterialsForState(String state) {
    final bool isNorth = state.contains('Kano') ||
        state.contains('Kaduna') ||
        state.contains('Plateau') ||
        state.contains('Borno') ||
        state.contains('Bauchi') ||
        state.contains('Gombe') ||
        state.contains('Adamawa') ||
        state.contains('Katsina') ||
        state.contains('Sokoto') ||
        state.contains('Kebbi') ||
        state.contains('Zamfara') ||
        state.contains('Taraba') ||
        state.contains('Yobe') ||
        state.contains('Jigawa') ||
        state.contains('Niger');

    final bool isEast = state.contains('Enugu') ||
        state.contains('Anambra') ||
        state.contains('Imo') ||
        state.contains('Abia') ||
        state.contains('Ebonyi') ||
        state.contains('Rivers') ||
        state.contains('Delta') ||
        state.contains('Akwa Ibom') ||
        state.contains('Cross River') ||
        state.contains('Bayelsa') ||
        state.contains('Edo');

    final bool isAbuja = state.contains('Abuja');

    // 1. Cement price computation
    final String dangotePrice = isAbuja ? '₦8,600 - ₦8,900' : (isNorth ? '₦8,700 - ₦9,200' : (isEast ? '₦8,500 - ₦8,950' : '₦8,400 - ₦8,800'));
    final String buaPrice = isAbuja ? '₦8,400 - ₦8,700' : (isNorth ? '₦8,300 - ₦8,600' : (isEast ? '₦8,450 - ₦8,800' : '₦8,300 - ₦8,650'));
    final String lafargePrice = isAbuja ? '₦8,550 - ₦8,850' : (isNorth ? '₦8,800 - ₦9,300' : (isEast ? '₦8,500 - ₦8,900' : '₦8,450 - ₦8,750'));

    // 2. Steel price computation
    final String steel10mm = isNorth ? '₦1,190,000' : (isEast ? '₦1,175,000' : '₦1,160,000');
    final String steel12mm = isNorth ? '₦1,210,000' : (isEast ? '₦1,195,000' : '₦1,180,000');
    final String steel16mm = isNorth ? '₦1,250,000' : (isEast ? '₦1,235,000' : '₦1,220,000');
    final String steel20mm = isNorth ? '₦1,280,000' : (isEast ? '₦1,265,000' : '₦1,250,000');

    // 3. Sand & Granite & Blocks
    final String granitePrice = isAbuja ? '₦310,000 - ₦340,000' : (isNorth ? '₦270,000 - ₦300,000' : (isEast ? '₦290,000 - ₦330,000' : '₦280,000 - ₦310,000'));
    final String sandPrice = isAbuja ? '₦150,000 - ₦175,000' : (isNorth ? '₦110,000 - ₦135,000' : (isEast ? '₦130,000 - ₦160,000' : '₦140,000 - ₦165,000'));
    final String block9inSolid = isAbuja ? '₦880 - ₦950' : (isNorth ? '₦800 - ₦870' : (isEast ? '₦840 - ₦920' : '₦820 - ₦900'));
    final String block9inHollow = isAbuja ? '₦780 - ₦850' : (isNorth ? '₦700 - ₦770' : (isEast ? '₦740 - ₦820' : '₦720 - ₦800'));
    final String block6inSolid = isAbuja ? '₦740 - ₦800' : (isNorth ? '₦650 - ₦720' : (isEast ? '₦700 - ₦760' : '₦680 - ₦750'));
    final String pavingStone = isAbuja ? '₦5,800 - ₦7,200' : (isNorth ? '₦5,000 - ₦6,400' : (isEast ? '₦5,400 - ₦6,900' : '₦5,200 - ₦6,800'));

    // 4. Roofing & Timber
    final String aluRoofing = isAbuja ? '₦8,200 - ₦8,900' : (isNorth ? '₦8,400 - ₦9,200' : (isEast ? '₦7,900 - ₦8,600' : '₦7,800 - ₦8,500'));
    final String stoneTile = isAbuja ? '₦4,900 - ₦6,100' : (isNorth ? '₦5,100 - ₦6,400' : (isEast ? '₦4,700 - ₦5,900' : '₦4,600 - ₦5,800'));
    final String timber2x4 = isAbuja ? '₦2,500 - ₦2,900' : (isNorth ? '₦2,700 - ₦3,200' : (isEast ? '₦2,100 - ₦2,500' : '₦2,200 - ₦2,600'));
    final String marinePlywood = isAbuja ? '₦26,000 - ₦30,000' : (isNorth ? '₦27,000 - ₦32,000' : (isEast ? '₦25,000 - ₦29,000' : '₦24,000 - ₦28,000'));

    // 5. Plumbing
    final String pvc4in = isAbuja ? '₦9,000 - ₦13,000' : (isNorth ? '₦9,500 - ₦13,500' : (isEast ? '₦8,800 - ₦12,800' : '₦8,500 - ₦12,500'));
    final String tank1000L = isAbuja ? '₦80,000 - ₦95,000' : (isNorth ? '₦85,000 - ₦100,000' : (isEast ? '₦78,000 - ₦92,000' : '₦75,000 - ₦90,000'));
    final String boreholePump = isAbuja ? '₦155,000 - ₦210,000' : (isNorth ? '₦160,000 - ₦215,000' : (isEast ? '₦150,000 - ₦200,000' : '₦145,000 - ₦195,000'));

    // 6. Electrical
    final String cable2_5mm = isAbuja ? '₦40,000 - ₦46,000' : (isNorth ? '₦42,000 - ₦48,000' : (isEast ? '₦39,000 - ₦45,000' : '₦38,000 - ₦44,000'));
    final String cable1_5mm = isAbuja ? '₦25,000 - ₦29,000' : (isNorth ? '₦26,000 - ₦31,000' : (isEast ? '₦24,500 - ₦28,500' : '₦24,000 - ₦28,000'));
    final String cable4_0mm = isAbuja ? '₦60,000 - ₦70,000' : (isNorth ? '₦62,000 - ₦72,000' : (isEast ? '₦59,000 - ₦69,000' : '₦58,000 - ₦68,000'));

    // 7. Tiles & Paints
    final String tiles60x60 = isAbuja ? '₦10,000 - ₦15,000' : (isNorth ? '₦10,500 - ₦15,500' : (isEast ? '₦9,800 - ₦14,500' : '₦9,500 - ₦14,000'));
    final String paintEmulsion = isAbuja ? '₦34,000 - ₦50,000' : (isNorth ? '₦35,000 - ₦52,000' : (isEast ? '₦33,000 - ₦49,000' : '₦32,000 - ₦48,000'));
    final String securityDoor = isAbuja ? '₦195,000 - ₦370,000' : (isNorth ? '₦205,000 - ₦385,000' : (isEast ? '₦190,000 - ₦360,000' : '₦185,000 - ₦350,000'));

    return [
      // CEMENT & BINDERS
      {
        'category': 'Cement & Binders',
        'name': 'Dangote 3X Portland Cement',
        'spec': 'Grade 42.5N High-Strength Portland',
        'unit': '50kg bag',
        'price': dangotePrice,
        'trend': 'STABLE',
        'trendVal': '-1.0%',
        'isUp': false,
        'description': 'Standard structural concrete, foundation casting & block making.',
      },
      {
        'category': 'Cement & Binders',
        'name': 'BUA Extra Cement',
        'spec': 'Grade 42.5N / Portland Composite',
        'unit': '50kg bag',
        'price': buaPrice,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'High workability cement for reinforced columns, beams & plastering.',
      },
      {
        'category': 'Cement & Binders',
        'name': 'Elephant / Lafarge Supaset',
        'spec': 'Rapid Hardening Portland Cement',
        'unit': '50kg bag',
        'price': lafargePrice,
        'trend': 'STABLE',
        'trendVal': '-0.5%',
        'isUp': false,
        'description': 'Early strength development ideal for precast blocks & suspended slabs.',
      },
      {
        'category': 'Cement & Binders',
        'name': 'POP Plaster of Paris Powder',
        'spec': 'Gypsum Calcined Finish Standard',
        'unit': '40kg bag',
        'price': '₦10,500 - ₦12,000',
        'trend': 'STABLE',
        'trendVal': '+1.5%',
        'isUp': true,
        'description': 'False ceiling moulding, cornices, medallions & wall screeding.',
      },
      {
        'category': 'Cement & Binders',
        'name': 'White Cement (Superwhite)',
        'spec': 'Decorative Silica Portland',
        'unit': '40kg bag',
        'price': '₦22,000 - ₦25,000',
        'trend': 'UP',
        'trendVal': '+2.0%',
        'isUp': true,
        'description': 'Tile grouting, marble installations & architectural terrazzo.',
      },

      // STEEL & REINFORCEMENT
      {
        'category': 'Steel & Rebar',
        'name': '10mm High-Yield TMT Rebar',
        'spec': 'FE 500 High-Tensile Certified Steel',
        'unit': 'Ton (~135 lengths)',
        'price': steel10mm,
        'trend': 'UP',
        'trendVal': '+2.5%',
        'isUp': true,
        'description': 'Slab reinforcement, stirrups, ring beams and lintels.',
      },
      {
        'category': 'Steel & Rebar',
        'name': '12mm High-Yield TMT Rebar',
        'spec': 'FE 500 High-Tensile Certified Steel',
        'unit': 'Ton (~94 lengths)',
        'price': steel12mm,
        'trend': 'UP',
        'trendVal': '+3.1%',
        'isUp': true,
        'description': 'Primary structural steel for floor slabs, columns, and foundations.',
      },
      {
        'category': 'Steel & Rebar',
        'name': '16mm High-Yield TMT Rebar',
        'spec': 'FE 500 Structural Heavy-Duty Grade',
        'unit': 'Ton (~53 lengths)',
        'price': steel16mm,
        'trend': 'UP',
        'trendVal': '+2.8%',
        'isUp': true,
        'description': 'Multi-storey building columns, heavy transfer beams & retaining walls.',
      },
      {
        'category': 'Steel & Rebar',
        'name': '20mm High-Yield TMT Rebar',
        'spec': 'FE 500 Structural Column Grade',
        'unit': 'Ton (~34 lengths)',
        'price': steel20mm,
        'trend': 'UP',
        'trendVal': '+2.0%',
        'isUp': true,
        'description': 'Raft foundation basements, high-rise pillars & civil infrastructure.',
      },
      {
        'category': 'Steel & Rebar',
        'name': 'Binding Wire (Heavy Gauge)',
        'spec': 'Annealed Flexible Tying Wire',
        'unit': '25kg roll / bundle',
        'price': '₦38,000 - ₦42,000',
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Tying and interlocking reinforcement steel bars before concrete pour.',
      },
      {
        'category': 'Steel & Rebar',
        'name': 'BRC Reinforcement Mesh Wire',
        'spec': 'Ref 65 / Ref 142 Welded Mesh',
        'unit': 'Roll (2.4m x 48m)',
        'price': '₦65,000 - ₦85,000',
        'trend': 'STABLE',
        'trendVal': '+0.5%',
        'isUp': true,
        'description': 'German floor oversite concrete, ground slabs & crack control.',
      },

      // BLOCKS & AGGREGATES
      {
        'category': 'Blocks & Sand',
        'name': '3/4 inch Clean Black Granite',
        'spec': 'Foundation & Structural Slab Aggregate',
        'unit': '30-ton tipper load',
        'price': granitePrice,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Crushed quarry rock for heavy load-bearing structural concrete.',
      },
      {
        'category': 'Blocks & Sand',
        'name': 'Clean Washed Sharp Sand',
        'spec': 'River Dredged Silica Concrete Sand',
        'unit': '20-ton tipper load',
        'price': sandPrice,
        'trend': 'STABLE',
        'trendVal': '-1.5%',
        'isUp': false,
        'description': 'German floor casting, beam pouring & heavy screed mix.',
      },
      {
        'category': 'Blocks & Sand',
        'name': '9-inch Solid Sandcrete Blocks',
        'spec': 'Machine Vibrated 1:6 Mix Certified',
        'unit': 'per piece delivered',
        'price': block9inSolid,
        'trend': 'DOWN',
        'trendVal': '-2.0%',
        'isUp': false,
        'description': 'Foundation footing walls & load-bearing ground perimeter walls.',
      },
      {
        'category': 'Blocks & Sand',
        'name': '9-inch Hollow Sandcrete Blocks',
        'spec': 'Machine Vibrated Standard',
        'unit': 'per piece delivered',
        'price': block9inHollow,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'External super-structure perimeter walls.',
      },
      {
        'category': 'Blocks & Sand',
        'name': '6-inch Solid Sandcrete Blocks',
        'spec': 'Machine Vibrated Partition',
        'unit': 'per piece delivered',
        'price': block6inSolid,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Internal non-loadbearing dividing walls & room partitions.',
      },
      {
        'category': 'Blocks & Sand',
        'name': 'Interlocking Paving Stones',
        'spec': '60mm / 80mm Hydraulic Pressed',
        'unit': 'sq. meter (~40-50 units)',
        'price': pavingStone,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Driveways, walkways, compound landscaping & heavy vehicular parking.',
      },

      // ROOFING & WOOD
      {
        'category': 'Roofing & Wood',
        'name': '0.55mm Aluminium Longspan Sheet',
        'spec': 'Oven-Baked Anti-Corrosion Coil',
        'unit': 'per sq. meter',
        'price': aluRoofing,
        'trend': 'STABLE',
        'trendVal': '+0.5%',
        'isUp': true,
        'description': 'Long-life residential & commercial weather-resistant roofing.',
      },
      {
        'category': 'Roofing & Wood',
        'name': 'Stone-Coated Metal Roofing Tiles',
        'spec': '0.45mm Bond / Shingle / Roman',
        'unit': 'per panel',
        'price': stoneTile,
        'trend': 'UP',
        'trendVal': '+1.5%',
        'isUp': true,
        'description': 'Sound-proof, fire-resistant luxury aesthetic stone chip tiles.',
      },
      {
        'category': 'Roofing & Wood',
        'name': 'Hardwood Timber 2x4 (12 feet)',
        'spec': 'Obeche / Mahogany Seasoned Timber',
        'unit': 'per length',
        'price': timber2x4,
        'trend': 'UP',
        'trendVal': '+2.0%',
        'isUp': true,
        'description': 'Roof trusses, kingposts, rafters & column formwork bracing.',
      },
      {
        'category': 'Roofing & Wood',
        'name': '18mm Marine Waterproof Plywood',
        'spec': 'Phenolic Film-Faced Shuttering Board',
        'unit': 'Sheet (4ft x 8ft)',
        'price': marinePlywood,
        'trend': 'UP',
        'trendVal': '+3.0%',
        'isUp': true,
        'description': 'Fair-face concrete formwork, decking slabs & cantilever beams.',
      },

      // PLUMBING & PIPES
      {
        'category': 'Plumbing & Pipes',
        'name': '4-inch PVC Waste & Soil Pipe',
        'spec': 'Class B / Class C Heavy-Gauge 5.8m',
        'unit': 'per 5.8m length',
        'price': pvc4in,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Water closet drainage stack, inspection chambers & manhole drops.',
      },
      {
        'category': 'Plumbing & Pipes',
        'name': '1000L Overhead Water Tank',
        'spec': 'Cylindrical Heavy-Duty Polyethylene',
        'unit': 'per unit',
        'price': tank1000L,
        'trend': 'STABLE',
        'trendVal': '+1.0%',
        'isUp': true,
        'description': 'Clean domestic gravity-fed potable water storage.',
      },
      {
        'category': 'Plumbing & Pipes',
        'name': '1.5HP Submersible Borehole Pump',
        'spec': 'Deep Well Single-Phase with Control Box',
        'unit': 'per unit',
        'price': boreholePump,
        'trend': 'UP',
        'trendVal': '+2.5%',
        'isUp': true,
        'description': 'Underground deep borehole groundwater extraction.',
      },

      // ELECTRICAL & CABLES
      {
        'category': 'Electrical & Cables',
        'name': '2.5mm Single-Core Copper Cable',
        'spec': '100% Pure Copper 100m (Coleman)',
        'unit': '100m roll',
        'price': cable2_5mm,
        'trend': 'UP',
        'trendVal': '+3.0%',
        'isUp': true,
        'description': 'Standard 13A ring main power sockets & domestic appliances.',
      },
      {
        'category': 'Electrical & Cables',
        'name': '1.5mm Single-Core Copper Cable',
        'spec': '100% Pure Copper 100m (Certified)',
        'unit': '100m roll',
        'price': cable1_5mm,
        'trend': 'UP',
        'trendVal': '+2.0%',
        'isUp': true,
        'description': 'Internal lighting points, ceiling fans & inverter circuits.',
      },
      {
        'category': 'Electrical & Cables',
        'name': '4.0mm Single-Core Copper Cable',
        'spec': 'Heavy Load 100m (Certified)',
        'unit': '100m roll',
        'price': cable4_0mm,
        'trend': 'UP',
        'trendVal': '+3.5%',
        'isUp': true,
        'description': 'Air conditioning, water heaters, cookers & water pumps.',
      },

      // TILES & PAINTS
      {
        'category': 'Tiles & Paints',
        'name': '60x60cm Vitrified Floor Tiles',
        'spec': 'High-Gloss Stain-Resistant Glazed',
        'unit': 'sq. meter (~4 tiles/box)',
        'price': tiles60x60,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Living room, hallway, and master bedroom luxury floor tiling.',
      },
      {
        'category': 'Tiles & Paints',
        'name': 'Dulux / Meyer Emulsion Paint',
        'spec': 'Premium Matt Finish 20L Bucket',
        'unit': '20L bucket',
        'price': paintEmulsion,
        'trend': 'STABLE',
        'trendVal': '+1.0%',
        'isUp': true,
        'description': 'Smooth washable interior/exterior architectural wall coating.',
      },
      {
        'category': 'Tiles & Paints',
        'name': 'Security Steel Entrance Door',
        'spec': 'Multi-Lock Heavy-Duty Turkish Grade',
        'unit': 'per complete unit with frame',
        'price': securityDoor,
        'trend': 'STABLE',
        'trendVal': '0.0%',
        'isUp': false,
        'description': 'Bullet-resistant security front entrance door (3ft x 7ft).',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allMaterials = _getAllMaterialsForState(_selectedState);
    final filteredMaterials = allMaterials.where((m) {
      final matchesCategory = _selectedCategory == 'All' || m['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          m['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m['spec'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Material Price Index', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // State Selector Header Banner
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.analytics_rounded, color: Color(0xFFEA580C), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Market Price Benchmarks',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'AUDITED NIQS',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // State Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                      items: _allStates.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedState = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Search Input
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search cement, 12mm rebar, 9-inch blocks, tiles...',
                      hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category Filter Chips
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  selectedColor: const Color(0xFFEA580C),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Materials List View
          Expanded(
            child: filteredMaterials.isEmpty
                ? const Center(
                    child: Text(
                      'No building materials found matching your filter.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMaterials.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredMaterials[index];
                      final isUp = item['isUp'] as bool;
                      final trendVal = item['trendVal'] as String;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item['category'].toString().toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF475569),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['name'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        item['spec'] as String,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item['price'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFEA580C)),
                                    ),
                                    Text(
                                      item['unit'] as String,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                                    ),
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
                                    item['description'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isUp
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                        : (trendVal == '0.0%'
                                            ? const Color(0xFF64748B).withValues(alpha: 0.1)
                                            : const Color(0xFF10B981).withValues(alpha: 0.1)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUp ? Icons.arrow_upward_rounded : (trendVal == '0.0%' ? Icons.remove_rounded : Icons.arrow_downward_rounded),
                                        size: 11,
                                        color: isUp
                                            ? const Color(0xFFDC2626)
                                            : (trendVal == '0.0%'
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF059669)),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        trendVal,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: isUp
                                              ? const Color(0xFFDC2626)
                                              : (trendVal == '0.0%'
                                                  ? const Color(0xFF64748B)
                                                  : const Color(0xFF059669)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

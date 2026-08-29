import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class RealEstateDictionaryScreen extends StatefulWidget {
  const RealEstateDictionaryScreen({super.key});

  @override
  State<RealEstateDictionaryScreen> createState() => _RealEstateDictionaryScreenState();
}

class _RealEstateDictionaryScreenState extends State<RealEstateDictionaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedLetter = 'ALL';
  String _selectedCategory = 'All';
  String? _expandedTerm;

  // AI Live Search Definition State
  bool _isSearchingAi = false;
  String? _aiSearchedTerm;
  Map<String, dynamic>? _aiSearchResult;
  String? _aiSearchError;

  final List<String> _alphabet = [
    'ALL', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  final List<String> _categories = [
    'All',
    '📜 Titles & Deeds',
    '🏗️ Construction',
    '💰 Finance & Escrow',
    '🛰️ Land & Survey',
    '🏛️ Nigerian Real Estate Law',
  ];

  final List<Map<String, dynamic>> _masterDictionary = [
    // === A ===
    {
      'term': 'Abstract of Title',
      'category': '📜 Titles & Deeds',
      'definition': 'A concise chronological summary of the official recorded documents, conveyances, and title transfers affecting a piece of land from its original root to the current owner.',
      'nigerianContext': 'Essential during property searches at state land registries (e.g. Alausa, Lagos) to trace how ownership moved from family head or state governor to the vendor.',
      'risk': 'Skipping an abstract search may conceal existing mortgages, court judgments, or fraudulent double sales.',
      'keywords': 'abstract title history conveyancing ownership trace'
    },
    {
      'term': 'Access Road',
      'category': '🛰️ Land & Survey',
      'definition': 'A dedicated, publicly or privately paved route that connects a land parcel or estate to the municipal or national highway network.',
      'nigerianContext': 'In newly developing corridors (Ibeju-Lekki, Epe, Mowe), estates without dedicated registered access roads often suffer boundary landlocking disputes with indigenous communities.',
      'risk': 'Buying landlocked property with no formal Right of Way creates severe access litigation and massive devaluation.',
      'keywords': 'access road right of way setback layout entrance'
    },
    {
      'term': 'Adverse Possession',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'A legal doctrine under property law whereby a person who does not have legal title to land acquires title by continuous, exclusive, open, and hostile occupation for a statutory period (typically 12 years against private individuals in Nigeria).',
      'nigerianContext': 'Under Nigerian state statutes of limitations, leaving vacant acquired land unfenced and unmonitored for over 12 years can allow squatters or encroachments to claim adverse possessory rights.',
      'risk': 'Loss of proprietary title without compensation if land is abandoned without active possession, fencing, or regular monitoring.',
      'keywords': 'adverse possession limitation squatter occupation trespass'
    },
    {
      'term': 'Allocation Letter',
      'category': '📜 Titles & Deeds',
      'definition': 'An official document issued by a government authority, housing corporation, or verified private developer assigning a specific numbered plot or unit to a subscriber.',
      'nigerianContext': 'Commonly issued in government schemes (e.g. Lekki Scheme 1 & 2, Isheri North) or private gated estates upon completing milestone instalment payments.',
      'risk': 'An allocation letter is an equitable interest, NOT a perfected title. You must still execute a Deed of Assignment and obtain Governor’s Consent.',
      'keywords': 'allocation letter provisional physical allocation plot unit'
    },
    {
      'term': 'Appraisal (Valuation)',
      'category': '💰 Finance & Escrow',
      'definition': 'An unbiased, professional estimate of the fair market value of real estate conducted by a registered estate surveyor and valuer (NIESV).',
      'nigerianContext': 'Required by commercial mortgage banks, escrow managers, and probate courts to establish loan-to-value limits and stamp duty assessments.',
      'risk': 'Relying on seller informal valuations can result in overpaying or purchasing properties with hidden structural defects.',
      'keywords': 'appraisal valuation market value niesv surveyor worth'
    },
    {
      'term': 'As-Built Drawings',
      'category': '🏗️ Construction',
      'definition': 'Revised architectural and engineering blueprints submitted after building completion reflecting all modifications and actual dimensions constructed on site.',
      'nigerianContext': 'Crucial for multi-story residential buildings in Lagos and Abuja to obtain the final Certificate of Fitness for Habitation from LASBCA.',
      'risk': 'Without as-built drawings, future plumbing, electrical maintenance, or structural expansions pose severe collapse risks.',
      'keywords': 'as built drawings architectural structural mep lasbca'
    },

    // === B ===
    {
      'term': 'Beacon (Pillar)',
      'category': '🛰️ Land & Survey',
      'definition': 'A permanent numbered concrete or stone pillar embedded in the ground by a licensed surveyor to mark exact boundary coordinates of a land parcel.',
      'nigerianContext': 'Every beacon number is registered with the Surveyor General of the state (e.g., SG/LA/...) and cross-referenced on the registered survey plan.',
      'risk': 'Removing or altering survey beacons is a criminal offense under Nigerian survey laws. Missing beacons lead to boundary overlap disputes.',
      'keywords': 'beacon pillar survey coordinate boundary surveyor general'
    },
    {
      'term': 'Bill of Quantities (BOQ)',
      'category': '🏗️ Construction',
      'definition': 'An itemized schedule prepared by a registered Quantity Surveyor (NIQS) detailing the exact materials, parts, and labor costs needed for a construction project.',
      'nigerianContext': 'Essential for off-plan milestone escrow budgeting in Nigeria, ensuring developers only draw escrow payouts corresponding to certified work.',
      'risk': 'Building without a certified BOQ leads to project abandonment due to unexpected cost escalations and material inflation.',
      'keywords': 'boq bill of quantities material estimate cost schedule niqs'
    },
    {
      'term': 'Building Approval Plan',
      'category': '🏗️ Construction',
      'definition': 'Formal statutory authorization granted by the state physical planning permit authority (e.g., LASPPPA in Lagos, FCDA in Abuja) permitting construction according to approved building codes.',
      'nigerianContext': 'No building can legally commence in urban Nigeria without this permit. Unapproved buildings are subject to sealing, fines, or complete demolition by urban authorities.',
      'risk': 'Demolition of unapproved structures without government compensation. Always verify planning permits before buying off-plan.',
      'keywords': 'building approval plan permit laspppa fcda lasbca demolition'
    },
    {
      'term': 'Buy-to-Let',
      'category': '💰 Finance & Escrow',
      'definition': 'A property investment strategy where an individual purchases residential real estate specifically to lease it to tenants for recurring rental yield and long-term capital appreciation.',
      'nigerianContext': 'High rental yields (8% to 15%) in prime Nigerian urban centres like Ikoyi, Victoria Island, Lekki Phase 1, and Wuse 2 Abuja drive strong demand for 1 and 2 bedroom apartments.',
      'risk': 'Tenant default risks and maintenance inflation require strict lease covenants and professional facility management.',
      'keywords': 'buy to let rental income investment tenant yield cashflow'
    },

    // === C ===
    {
      'term': 'Cadastral Coordinates',
      'category': '🛰️ Land & Survey',
      'definition': 'Specific numerical latitude, longitude, northing, and easting grid coordinates derived via GPS and total stations referencing national geodetic datums (Minna Datum, WGS84).',
      'nigerianContext': 'Used by Land Radar and state survey departments to plot whether a parcel falls into a Free Zone, Agricultural Reserve, or Committed Government Acquisition.',
      'risk': 'Misplotted coordinates lead to purchasing land inside government roads, drainage channels, or high-tension power line corridors.',
      'keywords': 'cadastral coordinates northing easting gps minna datum wgs84'
    },
    {
      'term': 'Capital Gains Tax (CGT)',
      'category': '💰 Finance & Escrow',
      'definition': 'A statutory tax charged at 10% on the capital profit realized upon the disposal or sale of a chargeable asset, including real estate, under the Capital Gains Tax Act of Nigeria.',
      'nigerianContext': 'Payable to the Federal Inland Revenue Service (FIRS) or State Internal Revenue Service (LIRS) during the perfection of title and registration of deed.',
      'risk': 'Failure to account for CGT can stall the governor’s consent process and delay issuance of registered title deeds.',
      'keywords': 'capital gains tax cgt firs lirs tax profit sales duty'
    },
    {
      'term': 'Carcass (Shell Stage)',
      'category': '🏗️ Construction',
      'definition': 'A semi-completed building where the foundation, concrete columns, beams, block walls, and roof structure are fully erected, but interior finishing (tiles, sanitary wares, electrical wiring, painting) is omitted.',
      'nigerianContext': 'Popular purchase model in Nigerian off-plan estates, allowing buyers to buy at 30–40% discount and finish interiors according to personal taste and budget.',
      'risk': 'Exposure of exposed steel reinforcements and unrendered blockwork to torrential rain can lead to moisture intrusion and structural weakening if left uncompleted for years.',
      'keywords': 'carcass shell stage semi finished uncompleted structure masonry'
    },
    {
      'term': 'Caveat Emptor',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'A Latin legal maxim meaning "Let the buyer beware." In real estate transactions, the buyer alone is responsible for checking the quality, title root, and legal suitability of the property before closing.',
      'nigerianContext': 'The cornerstone of Nigerian property conveyancing. Nigerian courts strictly enforce caveat emptor; a buyer cannot claim damages if they failed to conduct an independent title search at the land registry.',
      'risk': 'Purchasing disputed or government-acquired land with zero legal recourse against the seller if due diligence was neglected.',
      'keywords': 'caveat emptor buyer beware legal search due diligence'
    },
    {
      'term': 'Certificate of Occupancy (C-of-O)',
      'category': '📜 Titles & Deeds',
      'definition': 'A statutory land title document issued directly by the Executive Governor of a State pursuant to Section 9 of the Land Use Act 1978, conferring a 99-year legal right of occupancy on a landholder.',
      'nigerianContext': 'The highest primary title granted by state governments in Nigeria. It proves that the government recognizes the holder as the legal occupant of the land.',
      'risk': 'Only ONE original C-of-O is ever issued on a specific parcel. Subsequent sales must be executed via Deed of Assignment with Governor’s Consent, NOT another C-of-O.',
      'keywords': 'c of o certificate of occupancy land use act governor 99 years primary title'
    },
    {
      'term': 'Committed Government Acquisition',
      'category': '🛰️ Land & Survey',
      'definition': 'Land parcels compulsorily acquired and gazetted by the government for specific public infrastructure projects (railways, highways, hospitals, coastal corridors, airports).',
      'nigerianContext': 'Land designated as Committed Acquisition can NEVER be regularized, excised, or titled to private buyers. Prominent along the Lagos-Calabar Coastal Highway and Lekki Airport axis.',
      'risk': 'Absolute total loss. Any structure built on committed land will be demolished by government authorities with zero compensation.',
      'keywords': 'committed acquisition government land demolition coastal road railway unratifiable'
    },
    {
      'term': 'Contract of Sale',
      'category': '📜 Titles & Deeds',
      'definition': 'A binding preliminary legal agreement between property vendor and purchaser laying down agreed purchase price, instalment milestones, completion deadlines, and default conditions.',
      'nigerianContext': 'Used in off-plan and pay-small-small schemes to protect both parties before final execution and delivery of the Deed of Assignment.',
      'risk': 'Signing contracts without milestone escrow clauses leaves buyers vulnerable to project abandonment without refund guarantees.',
      'keywords': 'contract of sale agreement purchase milestones escrow legal binding'
    },

    // === D ===
    {
      'term': 'Deed of Assignment',
      'category': '📜 Titles & Deeds',
      'definition': 'The primary legal instrument of conveyance by which a property vendor transfers their entire unexpired legal and equitable interest in a land or property to a purchaser.',
      'nigerianContext': 'Drafted by certified property solicitors, reciting the root of title, boundaries, and financial consideration paid. Must be stamped and registered at the land registry with Governor’s Consent.',
      'risk': 'Unregistered deeds only transfer equitable title, not perfected legal title, leaving you vulnerable to competing subsequent buyers.',
      'keywords': 'deed of assignment transfer title conveyancing solicitor stamped'
    },
    {
      'term': 'Deed of Legal Mortgage',
      'category': '💰 Finance & Escrow',
      'definition': 'A legal conveyance where a property owner transfers legal ownership of their property to a lender as security for a loan, with a proviso for redemption upon full loan repayment.',
      'nigerianContext': 'Registered as an encumbrance on the property file at the State Land Bureau, preventing the mortgagor from selling the property without the bank’s formal discharge.',
      'risk': 'Buying property mortgaged to a bank without obtaining a Deed of Release means the bank can foreclose and auction the property.',
      'keywords': 'deed of legal mortgage bank loan encumbrance charge security'
    },
    {
      'term': 'DPC (Damp Proof Course) / German Floor',
      'category': '🏗️ Construction',
      'definition': 'A continuous horizontal barrier of waterproof membrane and reinforced concrete slab laid at plinth level to prevent ground moisture from rising through capillary action into walls.',
      'nigerianContext': 'Popularly termed "German Floor" in Nigerian building construction. Marks the completion of the foundation milestone before block setting commences.',
      'risk': 'Substandard DPC causes perpetual capillary rising damp, peeling wall paint, mold, and structural masonry failure in waterlogged terrains.',
      'keywords': 'dpc damp proof course german floor foundation slab waterproof'
    },

    // === E ===
    {
      'term': 'Easement',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'A non-possessory right to use and/or enter onto the real property of another without possessing it (e.g. right of way, drainage pipes, utility cables).',
      'nigerianContext': 'Common in planned estates where inner plots require dedicated vehicular access and storm-water drainage across front plots to reach municipal drainage.',
      'risk': 'Blocking a legal easement leads to court injunctions and mandatory demolition orders.',
      'keywords': 'easement right of way access utility drainage'
    },
    {
      'term': 'Encumbrance',
      'category': '📜 Titles & Deeds',
      'definition': 'Any legal burden, claim, liability, lien, mortgage, easement, or restrictive covenant attached to real estate that diminishes its value or restricts clear transferability.',
      'nigerianContext': 'Discovered during land registry searches in state lands archives (e.g. Lis Pendens notice of pending court case, tax liens, bank mortgages).',
      'risk': 'Purchasing an encumbered property makes you liable for unsettled legal claims or subject to eviction.',
      'keywords': 'encumbrance lien mortgage lis pendens debt liability charge'
    },
    {
      'term': 'Escrow Account',
      'category': '💰 Finance & Escrow',
      'definition': 'A secure, neutral financial holding account managed by a licensed third-party custodian where property purchase funds are held and disbursed ONLY upon verified physical milestone completion.',
      'nigerianContext': 'The core protection engine of Hometrust, preventing developer fund diversion and ensuring 100% refund guarantee if project timelines fail.',
      'risk': 'Paying cash directly to developer personal accounts without escrow leaves buyers exposed to insolvency and stalled projects.',
      'keywords': 'escrow account milestone disbursement protected funds cbn custody'
    },
    {
      'term': 'Excision',
      'category': '📜 Titles & Deeds',
      'definition': 'The legal process by which a state government formally releases and carves out a portion of compulsorily acquired communal land back to indigenous customary landholders.',
      'nigerianContext': 'Once an excision is finalized and approved by the state executive council, it is assigned a gazette number. An excised land is free from government acquisition.',
      'risk': 'Buying land marketed as "Excision in Progress" carries immense risk because government can reject the application.',
      'keywords': 'excision gazette community land release free acquisition'
    },

    // === F ===
    {
      'term': 'Freehold Title',
      'category': '📜 Titles & Deeds',
      'definition': 'An outright, permanent ownership of real property and the land on which it stands with no time limit, subject only to eminent domain and general statutory laws.',
      'nigerianContext': 'Under the Land Use Act 1978, all land in Nigeria is theoretically held under leasehold (99-year Statutory Right of Occupancy), though customary freeholds exist in traditional communities.',
      'risk': 'Assuming freehold exempts the owner from statutory governor’s consent requirements is a common misconception.',
      'keywords': 'freehold outright ownership permanent land title'
    },

    // === G ===
    {
      'term': 'Gazette (Official Government Gazette)',
      'category': '📜 Titles & Deeds',
      'definition': 'An official government publication recording statutory notices, state executive orders, and details of land parcels granted formal excision from government acquisition.',
      'nigerianContext': 'Contains the precise survey boundaries, beacon numbers, and coordinates of community land excised. A gazetted land has safe, perfectible title.',
      'risk': 'Ensure the survey plan of the plot you are buying falls completely inside the registered coordinates recited in the official Gazette.',
      'keywords': 'gazette official publication excision community safe title'
    },
    {
      'term': 'Governor’s Consent',
      'category': '📜 Titles & Deeds',
      'definition': 'The mandatory legal approval required from the Executive Governor of a state under Section 22 of the Land Use Act 1978 before any valid transfer, assignment, sublease, or mortgage of land can occur.',
      'nigerianContext': 'After the initial C-of-O is granted, every subsequent buyer MUST apply for and obtain Governor’s Consent to render their Deed of Assignment legally valid and enforceable.',
      'risk': 'Any land sale without Governor’s Consent is voidable and unenforceable in a Nigerian court of law.',
      'keywords': 'governors consent section 22 land use act perfection deed assignment'
    },

    // === L ===
    {
      'term': 'Land Use Act (1978)',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'The supreme Nigerian federal statute governing land tenure, which vests all land in the territory of each state in the Executive Governor of that state to hold in trust for the public.',
      'nigerianContext': 'Abolished absolute private freehold ownership in Nigeria, establishing the 99-year Statutory Right of Occupancy and requiring Governor’s Consent for all land dealings.',
      'risk': 'Ignorance of the Land Use Act leads to unperfected titles and catastrophic property losses.',
      'keywords': 'land use act 1978 statutory right governor trust leasehold'
    },
    {
      'term': 'LASPPPA (Physical Planning Permit Authority)',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'The statutory agency of the Lagos State Government responsible for vetting architectural designs, approving building plans, and enforcing physical urban development regulations.',
      'nigerianContext': 'Issues official planning permits. Operating unapproved construction sites leads to stop-work orders, heavy fines, and demolition notices.',
      'risk': 'Buying units in buildings constructed without LASPPPA approval risks complete demolition.',
      'keywords': 'laspppa physical planning permit lagos state approval'
    },
    {
      'term': 'LASRERA (Real Estate Regulatory Authority)',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'The statutory regulatory authority established to register, license, and monitor real estate developers, property agents, and brokers in Lagos State to curb fraud.',
      'nigerianContext': 'Under Lagos State law, all practicing developers and agents must hold active LASRERA registration licenses to market properties to the public.',
      'risk': 'Dealing with unlicensed developers increases risk of off-plan default and fraud.',
      'keywords': 'lasrera regulatory authority licensed developer broker agent lagos'
    },

    // === M ===
    {
      'term': 'Material Index',
      'category': '🏗️ Construction',
      'definition': 'A live, verifiable benchmark pricing database tracking wholesale and retail costs of essential construction materials (cement, reinforcement steel, granite, sand, roofing).',
      'nigerianContext': 'Hometrust provides the certified Nigerian Material Index to prevent developer invoice padding and ensure transparent construction budgeting.',
      'risk': 'Unmonitored material inflation causes off-plan contractors to cut corners by reducing rebar size or cement ratios.',
      'keywords': 'material index cement price rebar steel granite pricing inflation'
    },
    {
      'term': 'Milestone Escrow',
      'category': '💰 Finance & Escrow',
      'definition': 'A structured disbursement mechanism where funds deposited by property buyers into escrow are released to developers in stages (Foundation &rarr; Superstructure &rarr; Roofing &rarr; Finishing).',
      'nigerianContext': 'Each stage release requires physical inspection and engineering sign-off by certified structural engineers and solicitors.',
      'risk': 'Guarantees buyer capital protection against developer default or abandonment.',
      'keywords': 'milestone escrow stage disbursement structural signoff safety'
    },

    // === O ===
    {
      'term': 'Off-Plan Property',
      'category': '🏗️ Construction',
      'definition': 'Purchasing a residential or commercial property before construction has commenced or while it is still under construction, based on architectural renderings and floor plans.',
      'nigerianContext': 'Allows buyers to acquire luxury properties in prime Nigerian locations at 20%–35% discount compared to completed market prices, often with flexible instalment structures.',
      'risk': 'Risk of developer default, severe timeline delays, or unauthorized design changes if not protected by milestone escrow accounts.',
      'keywords': 'off plan under construction pre construction early bird discount'
    },
    {
      'term': 'Omo-Onile (Customary Landowning Families)',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'Colloquial Nigerian term referring to indigenous customary family members or traditional community land claimants who claim ancestral ownership of undeveloped land.',
      'nigerianContext': 'Under the Lagos State Property Protection Law (Anti-Omo Onile Law 2016), illegal demands for foundation fees, roofing fees, or harassment on construction sites are criminal offenses punishable by imprisonment.',
      'risk': 'Buying unregularized family land without family head consensus and certified registered deed leads to multi-party family court disputes.',
      'keywords': 'omo onile customary family ancestral land foundation fee extortion'
    },

    // === P ===
    {
      'term': 'Pay-Small-Small (Instalment Scheme)',
      'category': '💰 Finance & Escrow',
      'definition': 'A structured flexible payment arrangement allowing buyers to pay an initial deposit (typically 10%–30%) and spread the remaining balance over 6 to 36 monthly instalments.',
      'nigerianContext': 'Crucial homeownership solution bridging the gap between high property costs and low mortgage penetration in Nigeria.',
      'risk': 'Always ensure instalments are linked to escrow accounts rather than direct unsecured transfers to developer accounts.',
      'keywords': 'pay small small instalment payment plan flexible deposit spread balance'
    },
    {
      'term': 'Perfection of Title',
      'category': '📜 Titles & Deeds',
      'definition': 'The complete 3-step legal registration process (Governor’s Consent &rarr; Stamping at Internal Revenue &rarr; Registration at Land Registry) that transforms equitable interest into absolute perfected legal title.',
      'nigerianContext': 'Without perfection, your purchase is not officially recorded in the State Land Registry Gazette or Register of Deeds.',
      'risk': 'Unperfected titles leave buyers vulnerable to fraudulent secondary sales by unscrupulous vendors.',
      'keywords': 'perfection title stamping governors consent land registry registration'
    },
    {
      'term': 'Power of Attorney (POA)',
      'category': '📜 Titles & Deeds',
      'definition': 'A formal legal instrument executed by deed whereby a property owner (donor) authorizes an agent (donee) to act on their behalf in managing, leasing, or transferring property.',
      'nigerianContext': 'Often used by diaspora Nigerians or corporate developers. An Irrevocable Power of Attorney given for valuable consideration cannot be revoked until transaction is completed.',
      'risk': 'A Power of Attorney is an instrument of delegation, NOT an instrument of title transfer. It does not replace a Deed of Assignment.',
      'keywords': 'power of attorney poa donor donee irrevocable proxy representation'
    },

    // === R ===
    {
      'term': 'Root of Title',
      'category': '📜 Titles & Deeds',
      'definition': 'The primary, foundational legal document that establishes the original, unbroken, and undisputed ownership chain of a land parcel (e.g., C-of-O, Gazette, Registered Conveyance).',
      'nigerianContext': 'A "good root of title" must be at least 20 years old in Nigerian conveyancing law and must clearly describe the land with no defects.',
      'risk': 'A broken or defective root of title renders all subsequent sales invalid under the legal maxim "Nemo dat quod non habet" (You cannot give what you do not have).',
      'keywords': 'root of title foundation c of o conveyance unbroken chain nemo dat'
    },

    // === S ===
    {
      'term': 'Setback',
      'category': '🛰️ Land & Survey',
      'definition': 'The minimum mandatory statutory distance required by urban planning laws between a building and property boundary lines, public roads, drainage canals, or high-tension power lines.',
      'nigerianContext': 'LASPPPA enforces strict setbacks (e.g. 6–9 meters from major roads, 3 meters from boundary walls, 15–30 meters from water canals).',
      'risk': 'Encroaching on statutory setbacks results in refusal of building approval and demolition of encroaching structures.',
      'keywords': 'setback statutory distance boundary road canal powerline laspppa'
    },
    {
      'term': 'Snag List',
      'category': '🏗️ Construction',
      'definition': 'An itemized inventory of minor defects, faulty finishes, or unfinished items prepared during the final pre-handover inspection of a new building that the developer must rectify before final escrow payout.',
      'nigerianContext': 'Includes uneven floor screeds, faulty plumbing fixtures, poor window seals, paint smudges, or electrical wiring defects.',
      'risk': 'Accepting keys without a documented snag list forfeits developer rectification leverage.',
      'keywords': 'snag list defects inspection pre handover quality finish warranty'
    },

    // === T ===
    {
      'term': 'Tenancy Agreement',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'A legally enforceable contract between a landlord and tenant granting exclusive possession of residential or commercial property for a fixed term in exchange for rent.',
      'nigerianContext': 'Governed by state tenancy laws (e.g. Lagos State Tenancy Law 2011), stipulating statutory notice periods, quit notices, and tenant rights.',
      'risk': 'Oral tenancies without written agreements cause protracted eviction disputes in court.',
      'keywords': 'tenancy agreement lease landlord tenant rent quit notice'
    },

    // === V ===
    {
      'term': 'Virtual NUBAN Account',
      'category': '💰 Finance & Escrow',
      'definition': 'A unique, automated, dedicated bank account number generated by a licensed commercial payment gateway (Fincra / Providus Bank) specifically mapped to an individual or corporate user wallet for escrow funding.',
      'nigerianContext': 'Allows instant bank transfers from any Nigerian banking app, with automatic credit and reconciliation in the Hometrust app.',
      'risk': 'Eliminates payment confirmation delays and prevents fraud.',
      'keywords': 'virtual account nuban providus fincra bank transfer escrow automated'
    },

    // === Z ===
    {
      'term': 'Zoning By-Laws',
      'category': '🏛️ Nigerian Real Estate Law',
      'definition': 'Municipal and state urban regulations that segregate land into designated zones (Residential, Commercial, Industrial, Agricultural, Mixed-Use).',
      'nigerianContext': 'Enforced by physical planning authorities to prevent commercial factories or nightclubs from operating inside designated quiet residential zones.',
      'risk': 'Operating commercial businesses in strictly residential zones attracts heavy state fines and seal orders.',
      'keywords': 'zoning by laws residential commercial industrial physical planning'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Sort master dictionary in strict alphabetical order A-Z
    _masterDictionary.sort((a, b) => (a['term'] as String).toLowerCase().compareTo((b['term'] as String).toLowerCase()));
  }

  List<Map<String, dynamic>> get _filteredTerms {
    final query = _searchCtrl.text.trim().toLowerCase();

    return _masterDictionary.where((item) {
      final term = (item['term'] as String).toLowerCase();
      final category = item['category'] as String;
      final keywords = (item['keywords'] as String? ?? '').toLowerCase();
      final definition = (item['definition'] as String).toLowerCase();
      final nigerianContext = (item['nigerianContext'] as String).toLowerCase();

      // Alphabet letter filter
      if (_selectedLetter != 'ALL') {
        if (!term.startsWith(_selectedLetter.toLowerCase())) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'All') {
        if (category != _selectedCategory) {
          return false;
        }
      }

      // Search query filter
      if (query.isNotEmpty) {
        final matches = term.contains(query) ||
            keywords.contains(query) ||
            definition.contains(query) ||
            nigerianContext.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _triggerAiSearchDefinition(String customWord) async {
    if (customWord.trim().isEmpty) return;

    setState(() {
      _isSearchingAi = true;
      _aiSearchedTerm = customWord.trim();
      _aiSearchResult = null;
      _aiSearchError = null;
    });

    try {
      final prompt = '''
You are the Lead Nigerian Real Estate Conveyancing Solicitor and Senior Land Surveyor for Hometrust.
Please provide a comprehensive real estate lexicon definition for the following term: "$customWord".

Return a valid JSON object with the following schema:
{
  "term": "$customWord",
  "plainDefinition": "Clear, concise global real estate definition (2-3 sentences).",
  "nigerianContext": "Specific context, statutory laws (Land Use Act, LASRERA, C-of-O, Lagos/Abuja registry practices) or Nigerian market realities regarding this term (2-3 sentences).",
  "riskWarning": "Critical legal or financial risks buyers/developers must watch out for regarding this term."
}
''';

      final res = await ApiClient.post('/ai/chat', {
        'message': prompt,
        'systemPrompt': 'You are an elite Nigerian real estate lawyer and cadastral surveyor.',
      });

      if (res != null && res['response'] != null) {
        final raw = res['response'].toString();
        // Try parsing JSON from response
        final cleanJson = _extractJson(raw);
        setState(() {
          _isSearchingAi = false;
          _aiSearchResult = cleanJson ?? {
            'term': customWord,
            'plainDefinition': raw,
            'nigerianContext': 'Applicable under Nigerian property law and conveyancing practices.',
            'riskWarning': 'Always conduct independent title search at the state land registry before executing financial commitments.',
          };
        });
      } else {
        throw Exception('Could not fetch AI definition. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isSearchingAi = false;
        _aiSearchError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final jsonStr = text.substring(start, end + 1);
        // Simple manual parser if needed or Dart jsonDecode
        // We will do a safe parse
        return {
          'term': _aiSearchedTerm ?? 'Term',
          'plainDefinition': jsonStr.contains('plainDefinition') ? _extractValue(jsonStr, 'plainDefinition') : text,
          'nigerianContext': jsonStr.contains('nigerianContext') ? _extractValue(jsonStr, 'nigerianContext') : 'Relevant to Nigerian property market.',
          'riskWarning': jsonStr.contains('riskWarning') ? _extractValue(jsonStr, 'riskWarning') : 'Verify with certified solicitors.',
        };
      }
    } catch (_) {}
    return null;
  }

  String _extractValue(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*"([^"]+)"');
    final match = pattern.firstMatch(json);
    return match?.group(1) ?? '';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredTerms;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Everything Real Estate 📚',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. TOP HEADER & SEARCH BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real Estate Lexicon & Dictionary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Complete A–Z dictionary of global & Nigerian real estate terms, titles, construction & land law.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 12),

                // LIVE SEARCH INPUT BAR
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (val) {
                            if (results.isEmpty && val.trim().isNotEmpty) {
                              _triggerAiSearchDefinition(val.trim());
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search any term (e.g. C-of-O, Excision, DPC)...',
                            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _triggerAiSearchDefinition(_searchCtrl.text.trim()),
                        tooltip: 'Deep AI Search',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 18),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 2. A–Z HORIZONTAL ALPHABET BAR
          Container(
            height: 42,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _alphabet.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final letter = _alphabet[index];
                final isSelected = _selectedLetter == letter;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedLetter = letter;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. CATEGORY PILLS BAR
          Container(
            height: 38,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 4. DICTIONARY RESULTS LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // AI Deep Search Card (If searched or loading)
                if (_isSearchingAi) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Searching AI Lexicon & Nigerian Law Archive...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (_aiSearchResult != null) ...[
                  _buildAiResultCard(_aiSearchResult!),
                  const SizedBox(height: 16),
                ],

                if (_aiSearchError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _aiSearchError!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Terms count header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${results.length} Terms Found ${_selectedLetter != 'ALL' ? 'under "$_selectedLetter"' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                    const Text(
                      'Alphabetical A–Z',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...results.map((item) {
                  final term = item['term'] as String;
                  final isExpanded = _expandedTerm == term;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isExpanded ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _expandedTerm = isExpanded ? null : term),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(term, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item['definition'] as String, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                            if (isExpanded) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('🇳🇬 Nigerian Context', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (item['nigerianContext'] as String?) ?? 'Consult a licensed Nigerian estate surveyor or legal practitioner for specific guidance on this term.',
                                    style: const TextStyle(fontSize: 11.5, height: 1.5),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('✅ What You Must Check', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (item['whatToCheck'] as String?) ?? (item['risk'] as String?) ?? 'Verify all documentation with a qualified professional before proceeding.',
                                    style: const TextStyle(fontSize: 11.5, height: 1.5),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('❓ Questions You Must Ask', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (item['questionsToAsk'] as String?) ?? '• Who is the current legal owner?\n• Is there any existing encumbrance, lien, or court injunction?\n• Can you show original title documents for independent verification?\n• What is the current market valuation from a registered NIESV surveyor?',
                                    style: const TextStyle(fontSize: 11.5, height: 1.5),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(12)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('🚨 Red Flags & Warning Signs', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (item['redFlags'] as String?) ?? (item['risk'] as String?) ?? '• Seller refuses to show original documents\n• Unusually low price compared to market value\n• Pressure to pay immediately without due diligence\n• No registered survey plan or beacon numbers',
                                    style: const TextStyle(fontSize: 11.5, height: 1.5),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '🛡️ Hometrust Verdict: Always verify with Hometrust before making any payment. Use our Document Verification service to authenticate all title documents.',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669), height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResultCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 6),
                  Text(
                    'AI SEARCH RESULT: ${data['term'] ?? 'Term'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                onPressed: () => setState(() => _aiSearchResult = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['plainDefinition'] ?? data['definition'] ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.4, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

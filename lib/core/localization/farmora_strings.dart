/// Simple lightweight localization for Farmora.
/// Supports English, Sinhala (සිංහල) and Tamil (தமிழ்).
/// Usage: `FarmoraStrings.of(context).orders`
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/farmora_state.dart';

class FarmoraStrings {
  final BuildContext context;

  FarmoraStrings._(this.context);

  static FarmoraStrings of(BuildContext context) => FarmoraStrings._(context);

  /// Map of string key -> translations keyed by language code.
  /// en = English, si = Sinhala, ta = Tamil.
  static const Map<String, Map<String, String>> _strings = {
    // ── Bottom nav ──
    'navHome': {
      'en': 'Home', 'si': 'මුල් පිටුව', 'ta': 'முகப்பு',
    },
    'navProducts': {
      'en': 'Products', 'si': 'නිෂ්පාදන', 'ta': 'தயாரிப்புகள்',
    },
    'navOrders': {
      'en': 'Orders', 'si': 'ඇණවුම්', 'ta': 'ஆர்டர்கள்',
    },
    'navEarnings': {
      'en': 'Earnings', 'si': 'ආදායම්', 'ta': 'வருவாய்',
    },
    'navProfile': {
      'en': 'Profile', 'si': 'පැතිකඩ', 'ta': 'சுயவிவரம்',
    },
    'navOverview': {
      'en': 'Overview', 'si': 'දළ විශ්ලේෂණය', 'ta': 'மேலோட்டம்',
    },
    'navJobs': {
      'en': 'Jobs', 'si': 'රැකියා', 'ta': 'வேலைகள்',
    },
    'navHistory': {
      'en': 'History', 'si': 'ඉතිහාසය', 'ta': 'வரலாறு',
    },
    'navUsers': {
      'en': 'Users', 'si': 'පරිශීලකයින්', 'ta': 'பயனர்கள்',
    },
    'navLogistics': {
      'en': 'Logistics', 'si': 'ලොජිස්ටික්ස්', 'ta': 'லாஜிஸ்டிக்ஸ்',
    },
    'navSettings': {
      'en': 'Settings', 'si': 'සැකසුම්', 'ta': 'அமைப்புகள்',
    },

    // ── Dashboard ──
    'goodMorning': {
      'en': 'Good Morning', 'si': 'සුබ උදෑසනක්', 'ta': 'காலை வணக்கம்',
    },
    'goodAfternoon': {
      'en': 'Good Afternoon', 'si': 'සුබ දහවලක්', 'ta': 'மதிய வணக்கம்',
    },
    'goodEvening': {
      'en': 'Good Evening', 'si': 'සුබ සැන්දෑවක්', 'ta': 'மாலை வணக்கம்',
    },
    'farmer': {
      'en': 'Farmer', 'si': 'ගොවියා', 'ta': 'விவசாயி',
    },
    'whatsHappening': {
      'en': "Here's what's happening with your farm today.",
      'si': 'ඔබේ ගොවිපලේ අද සිදුවන දේ මෙන්න.',
      'ta': 'இன்று உங்கள் பண்ணையில் நடக்கும் விஷயங்கள் இதோ.',
    },
    'todaysOrders': {
      'en': "Today's Orders", 'si': 'අද ඇණවුම්', 'ta': 'இன்றைய ஆர்டர்கள்',
    },
    'activeProducts': {
      'en': 'Active Products', 'si': 'සක්‍රීය නිෂ්පාදන', 'ta': 'செயலில் உள்ள தயாரிப்புகள்',
    },
    'pendingOrders': {
      'en': 'Pending Orders', 'si': 'බලාපොරොත්තු ඇණවුම්', 'ta': 'நிலுவையில் உள்ள ஆர்டர்கள்',
    },
    'monthEarnings': {
      'en': "This Month's Earnings", 'si': 'මෙම මාසයේ ආදායම', 'ta': 'இந்த மாத வருவாய்',
    },
    'listedForSale': {
      'en': 'Listed for sale', 'si': 'විකිණීමට ලක් කර ඇත', 'ta': 'விற்பனைக்கு பட்டியலிடப்பட்டது',
    },
    'awaitingResponse': {
      'en': 'Awaiting response', 'si': 'ප්‍රතිචාරයක් අපේක්ෂිතයි', 'ta': 'பதில் எதிர்பார்க்கப்படுகிறது',
    },
    'fromYesterday': {
      'en': '+2 from yesterday', 'si': '+2 ඊයේ සිට', 'ta': '+2 நேற்று முதல்',
    },
    'farmActivity': {
      'en': 'Farm Activity', 'si': 'ගොවිපල ක්‍රියාකාරකම', 'ta': 'பண்ணை செயல்பாடு',
    },
    'currentProduce': {
      'en': 'Your current produce', 'si': 'ඔබේ වත්මන් අස්වැන්න', 'ta': 'உங்கள் தற்போதைய அறுவடை',
    },
    'recentOrders': {
      'en': 'Recent Orders', 'si': 'මෑත ඇණවුම්', 'ta': 'சமீபத்திய ஆர்டர்கள்',
    },
    'quickActions': {
      'en': 'Quick Actions', 'si': 'ඉක්මන් ක්‍රියා', 'ta': 'விரைவு செயல்கள்',
    },
    'addProduce': {
      'en': 'Add Produce', 'si': 'අස්වැන්න එක් කරන්න', 'ta': 'அறுவடை சேர்க்க',
    },
    'manageOrders': {
      'en': 'Manage Orders', 'si': 'ඇණවුම් කළමනාකරණය', 'ta': 'ஆர்டர் நிர்வகிக்க',
    },
    'viewEarnings': {
      'en': 'View Earnings', 'si': 'ආදායම් බලන්න', 'ta': 'வருவாயை பார்க்க',
    },
    'editFarmProfile': {
      'en': 'Edit Farm Profile', 'si': 'ගොවිපල පැතිකඩ සංස්කරණය', 'ta': 'பண்ணை சுயவிவரத்தை திருத்து',
    },
    'healthyStock': {
      'en': 'Healthy Stock', 'si': 'සෞඛ්‍ය සම්පන්න තොගය', 'ta': 'ஆரோக்கியமான சரக்கு',
    },
    'lowStock': {
      'en': 'Low Stock', 'si': 'අඩු තොගය', 'ta': 'குறைந்த சரக்கு',
    },
    'outOfStock': {
      'en': 'Out of Stock', 'si': 'තොගය නොමැත', 'ta': 'சரக்கு இல்லை',
    },
    'activeOrders': {
      'en': 'active orders', 'si': 'සක්‍රීය ඇණවුම්', 'ta': 'செயலில் உள்ள ஆர்டர்கள்',
    },
    'available': {
      'en': 'available', 'si': 'ලබා ගත හැක', 'ta': 'கிடைக்கிறது',
    },

    // ── Orders ──
    'incomingOrders': {
      'en': 'Incoming Orders', 'si': 'පැමිණෙන ඇණවුම්', 'ta': 'வரும் ஆர்டர்கள்',
    },
    'pending': {
      'en': 'Pending', 'si': 'සම්බාධිත', 'ta': 'நிலுவையில்',
    },
    'accepted': {
      'en': 'Accepted', 'si': 'පිළිගත්', 'ta': 'ஏற்றுக்கொள்ளப்பட்டது',
    },
    'completed': {
      'en': 'Completed', 'si': 'සම්පූර්ණ', 'ta': 'முடிந்தது',
    },
    'accept': {
      'en': 'Accept', 'si': 'පිළිගන්න', 'ta': 'ஏற்றுக்கொள்',
    },
    'decline': {
      'en': 'Decline', 'si': 'ප්‍රතික්ෂේප කරන්න', 'ta': 'நிராகரிக்க',
    },
    'markDelivered': {
      'en': 'Mark as Delivered', 'si': 'බාරදුන් බවට සලකුණු කරන්න', 'ta': 'வழங்கப்பட்டதாக குறி',
    },
    'orderAccepted': {
      'en': 'Order accepted!', 'si': 'ඇණවුම පිළිගන්නා ලදී!', 'ta': 'ஆர்டர் ஏற்றுக்கொள்ளப்பட்டது!',
    },
    'orderDeclined': {
      'en': 'Order declined', 'si': 'ඇණවුම ප්‍රතික්ෂේප කරන ලදී', 'ta': 'ஆர்டர் நிராகரிக்கப்பட்டது',
    },
    'noPendingOrders': {
      'en': 'No pending orders', 'si': 'සම්බාධිත ඇණවුම් නොමැත', 'ta': 'நிலுவை ஆர்டர்கள் இல்லை',
    },
    'noAcceptedOrders': {
      'en': 'No accepted orders', 'si': 'පිළිගත් ඇණවුම් නොමැත', 'ta': 'ஏற்றுக்கொள்ளப்பட்ட ஆர்டர்கள் இல்லை',
    },
    'noCompletedOrders': {
      'en': 'No completed orders', 'si': 'සම්පූර්ණ කළ ඇණවුම් නොමැත', 'ta': 'முடிந்த ஆர்டர்கள் இல்லை',
    },

    // ── Profile ──
    'accountVerification': {
      'en': 'Account Verification', 'si': 'ගිණුම් තහවුරු කිරීම', 'ta': 'கணக்கு சரிபார்ப்பு',
    },
    'docsPending': {
      'en': '2 documents pending review', 'si': 'ලේඛන 2ක් සමාලෝචනය අපේක්ෂිතයි', 'ta': '2 ஆவணங்கள் மதிப்பாய்வுக்காக காத்திருக்கின்றன',
    },
    'accountRole': {
      'en': 'Account Role', 'si': 'ගිණුම් භූමිකාව', 'ta': 'கணக்கு பங்கு',
    },
    'current': {
      'en': 'Current: ', 'si': 'වත්මන්: ', 'ta': 'தற்போதைய: ',
    },
    'language': {
      'en': 'Language', 'si': 'භාෂාව', 'ta': 'மொழி',
    },
    'helpSupport': {
      'en': 'Help & Support', 'si': 'උපකාර සහ සහාය', 'ta': 'உதவி மற்றும் ஆதரவு',
    },
    'signOut': {
      'en': 'Sign Out', 'si': 'ඉවත් වන්න', 'ta': 'வெளியேறு',
    },
    'selectLanguage': {
      'en': 'Select Language', 'si': 'භාෂාව තෝරන්න', 'ta': 'மொழியை தேர்ந்தெடுக்கவும்',
    },

    // ── Products screen ──
    'myProducts': {
      'en': 'My Products', 'si': 'මගේ නිෂ්පාදන', 'ta': 'எனது தயாரிப்புகள்',
    },
    'searchProducts': {
      'en': 'Search my products...', 'si': 'මගේ නිෂ්පාදන සොයන්න...', 'ta': 'எனது தயாரிப்புகளை தேடுங்கள்...',
    },
    'allProducts': {
      'en': 'All Products', 'si': 'සියලු නිෂ්පාදන', 'ta': 'அனைத்து தயாரிப்புகள்',
    },
    'active': {
      'en': 'Active', 'si': 'සක්‍රීය', 'ta': 'செயலில்',
    },
    'outOfStockTab': {
      'en': 'Out of Stock', 'si': 'තොගය නොමැත', 'ta': 'சரக்கு இல்லை',
    },
    'activeBadge': {
      'en': 'ACTIVE', 'si': 'සක්‍්‍රීය', 'ta': 'செயலில்',
    },

    // ── Order detail ──
    'orderDetail': {
      'en': 'Order Detail', 'si': 'ඇණවුම් විස්තර', 'ta': 'ஆர்டர் விவரம்',
    },
    'newOrderRequest': {
      'en': 'New Order\\nRequest', 'si': 'නව ඇණවුම\\nඉල්ලීම', 'ta': 'புதிய ஆர்டர்\\nகோரிக்கை',
    },
    'pendingAcceptance': {
      'en': 'Pending\\nAcceptance', 'si': 'පිළිගැනීම\\nබලාපොරොත්තු', 'ta': 'ஏற்றுக்கொள்ள\\nநிலுவையில்',
    },
    'verifiedBuyer': {
      'en': 'Verified Commercial Buyer', 'si': 'තහවුරු කළ වාණිජ ගැනුම්කරු', 'ta': 'சரிபார்க்கப்பட்ட வணிக வாங்குபவர்',
    },
    'callBuyer': {
      'en': 'Call Buyer', 'si': 'ගැනුම්කරුට කතා කරන්න', 'ta': 'வாங்குபவரை அழைக்க',
    },
    'totalPayout': {
      'en': 'Total Payout', 'si': 'මුළු ගෙවීම', 'ta': 'மொத்த கட்டணம்',
    },
    'guaranteedEscrow': {
      'en': 'Guaranteed Escrow', 'si': 'සහතික කළ එස්ක්‍රෝ', 'ta': 'உறுதி செய்யப்பட்ட எஸ்க்ரோ',
    },
    'orderPlaced': {
      'en': 'Order Placed', 'si': 'ඇණවුම දමන ලදී', 'ta': 'ஆர்டர் செய்யப்பட்டது',
    },
    'produceDetails': {
      'en': 'Produce Details', 'si': 'අස්වැන්නේ විස්තර', 'ta': 'அறுவடை விவரங்கள்',
    },
    'harvestReady': {
      'en': 'Harvest Ready', 'si': 'අස්වැන්න සූදානම්', 'ta': 'அறுவடை தயார்',
    },
    'packagingProtocol': {
      'en': 'Packaging Protocol', 'si': 'ඇසුරුම් ක්‍රමය', 'ta': 'பேக்கேஜிங் முறை',
    },
    'packagingDesc': {
      'en': 'Crates sanitized, ventilated produce boxes. Keep shaded at dock.',
      'si': 'පෙට්ටි විෂබීජහරණය කර, වායු සමීකරණ පෙට්ටි. වරායේ දී සෙවනැල්ලේ තබන්න.',
      'ta': 'பெட்டிகள் சுத்தம் செய்யப்பட்டு, காற்றோட்டமான பெட்டிகள். கப்பல்துறையில் நிழலில் வைக்கவும்.',
    },
    'dispatch3pl': {
      'en': 'Farmora Dispatched 3PL Pickup', 'si': 'Farmora 3PL එකතු කිරීම යවා ඇත', 'ta': 'Farmora 3PL சேகரிப்பு அனுப்பியது',
    },
    'dispatch3plDesc': {
      'en': 'You only pack the harvest at your farm gate. Once accepted, Farmora automatically dispatches a verified 3PL driver to pick up and deliver to the buyer.',
      'si': 'ඔබ අස්වැන්න ගොවිපල දොරටුවේ දී පමණක් ඇසුරුම් කරන්න. පිළිගත් පසු, Farmora විසින් ස්වයංක්‍රීයව 3PL රථයක් යවා ගැනුම්කරුට බාරදෙයි.',
      'ta': 'நீங்கள் அறுவடையை பண்ணை வாயிலில் மட்டும் பேக்கேஜ் செய்யவும். ஏற்றுக்கொண்ட பிறகு, Farmora தானாகவே 3PL ஓட்டுநரை அனுப்பி வாங்குபவருக்கு வழங்கும்.',
    },
    'viewLogistics': {
      'en': 'View Logistics & Delivery Route Details', 'si': 'ලොජිස්ටික්ස් සහ බෙදාහැරීමේ මාර්ග විස්තර බලන්න', 'ta': 'லாஜிஸ்டிக்ஸ் மற்றும் டெலிவரி வழியை பார்க்க',
    },
    'reject': {
      'en': 'Reject', 'si': 'ප්‍රතික්ෂේප කරන්න', 'ta': 'நிராகரிக்க',
    },
    'acceptOrder': {
      'en': 'Accept Order', 'si': 'ඇණවුම පිළිගන්න', 'ta': 'ஆர்டரை ஏற்றுக்கொள்',
    },
    'orderRejected': {
      'en': 'Order rejected', 'si': 'ඇණවුම ප්‍රතික්ෂේප කරන ලදී', 'ta': 'ஆர்டர் நிராகரிக்கப்பட்டது',
    },

    // ── Logistics tracking ──
    'logisticsTitle': {
      'en': 'Order Detail', 'si': 'ඇණවුම් විස්තර', 'ta': 'ஆர்டர் விவரம்',
    },
    'driverEnRoute': {
      'en': 'Driver En Route for Pickup', 'si': 'රථය එකතු කිරීමට පැමිණෙමින්', 'ta': 'ஓட்டுநர் சேகரிக்க வருகிறார்',
    },
    'pickupToday': {
      'en': 'Pickup\\nToday', 'si': 'අද\\nඑකතු කිරීම', 'ta': 'இன்று\\nசேகரிப்பு',
    },
    'estimatedArrival': {
      'en': 'Estimated Arrival 25 mins (8:45 AM)', 'si': 'පැමිණීම විනාඩි 25 (පෙ.ව. 8:45)', 'ta': 'வருகை நிமிடம் 25 (காலை 8:45)',
    },
    'callDriver': {
      'en': 'Call Driver', 'si': 'රථයේ අයට කතා කරන්න', 'ta': 'ஓட்டுநரை அழைக்க',
    },
    'message': {
      'en': 'Message', 'si': 'පණිවිඩය', 'ta': 'செய்தி',
    },
    'routeWaypoints': {
      'en': 'Route Waypoints', 'si': 'මාර්ග ස්ථාන', 'ta': 'பாதை இடங்கள்',
    },
    'pickupOrigin': {
      'en': 'Pickup Origin', 'si': 'එකතු කිරීමේ ස්ථානය', 'ta': 'சேகரிப்பு இடம்',
    },
    'deliveryDestination': {
      'en': 'Delivery Destination', 'si': 'බාරදීමේ ගමනාන්තය', 'ta': 'டெலிவரி இலக்கு',
    },
    'orderLifecycle': {
      'en': 'Order Lifecycle', 'si': 'ඇණවුමේ ජීවන චක්‍රය', 'ta': 'ஆர்டர் வாழ்க்கை சுழற்சி',
    },
    'pickupChecklist': {
      'en': 'Pickup Checklist', 'si': 'එකතු කිරීමේ ලැයිස්තුව', 'ta': 'சேகரிப்பு பட்டியல்',
    },
    'done': {
      'en': 'Done', 'si': 'අවසන්', 'ta': 'முடிந்தது',
    },
    'confirmHanded': {
      'en': 'Confirm Produce Handed to Driver', 'si': 'රථයට අස්වැන්න ලබාදුන් බව තහවුරු කරන්න', 'ta': 'ஓட்டுநரிடம் அறுவடை வழங்கியதை உறுதிசெய்',
    },
    'escrowProtected': {
      'en': 'Escrow Guarantee Protected', 'si': 'එස්ක්‍රෝ සහතිකය ආරක්ෂිතයි', 'ta': 'எஸ்க்ரோ உத்தரவாதம் பாதுகாக்கப்பட்டது',
    },

    // ── Earnings ──
    'earningsDashboard': {
      'en': 'Earnings Dashboard', 'si': 'ආදායම් උපකරණ පුවරුව', 'ta': 'வருவாய் டாஷ்போர்டு',
    },
    'totalEarnings': {
      'en': 'Total Earnings', 'si': 'මුළු ආදායම', 'ta': 'மொத்த வருவாய்',
    },
    'thisMonth': {
      'en': 'This Month', 'si': 'මෙම මාසය', 'ta': 'இந்த மாதம்',
    },
    'thisWeek': {
      'en': 'This Week', 'si': 'මෙම සතිය', 'ta': 'இந்த வாரம்',
    },
    'pendingPayments': {
      'en': 'Pending Payments', 'si': 'බලාපොරොත්තු ගෙවීම්', 'ta': 'நிலுவை கட்டணங்கள்',
    },
    'viewAll': {
      'en': 'View All', 'si': 'සියල්ල බලන්න', 'ta': 'அனைத்தையும் பார்க்க',
    },
    'monthlyRevenue': {
      'en': 'Monthly Revenue', 'si': 'මාසික ආදායම', 'ta': 'மாத வருவாய்',
    },
    'recentEarnings': {
      'en': 'Recent Earnings', 'si': 'මෑත ආදායම්', 'ta': 'சமீபத்திய வருவாய்',
    },
    'monthly': {
      'en': 'Monthly', 'si': 'මාසික', 'ta': 'மாதாந்திர',
    },
    'weekly': {
      'en': 'Weekly', 'si': 'සතිපතා', 'ta': 'வாராந்திர',
    },

    // ── Help & Support ──
    'faq': {
      'en': 'Frequently Asked Questions', 'si': 'නිතර අසන ප්‍රශ්න', 'ta': 'அடிக்கடி கேட்கும் கேள்விகள்',
    },
    'contactUs': {
      'en': 'Contact Us', 'si': 'අප අමතන්න', 'ta': 'எங்களை தொடர்பு கொள்ள',
    },
    'faqOrders': {
      'en': 'How do orders work?', 'si': 'ඇණවුම් ක්‍රියා කරන්නේ කෙසේද?', 'ta': 'ஆர்டர்கள் எப்படி வேலை செய்கின்றன?',
    },
    'faqOrdersAnswer': {
      'en': 'A buyer places an order, you accept it, Farmora dispatches a 3PL driver who picks up your produce and delivers to the buyer. Payment is held in escrow and released on delivery.',
      'si': 'ගැනුම්කරු ඇණවුමක් දමයි, ඔබ එය පිළිගනී, Farmora 3PL රථයක් යවා අස්වැන්න ලබාගෙන ගැනුම්කරුට බාරදෙයි. මුදල එස්ක්‍රෝවේ තබා බාරදීමේ දී නිදහස් කරයි.',
      'ta': 'வாங்குபவர் ஆர்டர் செய்கிறார், நீங்கள் ஏற்றுக்கொள்கிறீர்கள், Farmora 3PL ஓட்டுநரை அனுப்பி அறுவடையை பெற்று வாங்குபவருக்கு வழங்குகிறது. பணம் எஸ்க்ரோவில் வைக்கப்பட்டு டெலிவரியில் விடுவிக்கப்படும்.',
    },
    'faqPayout': {
      'en': 'When do I get paid?', 'si': 'මට ගෙවන්නේ කවදාද?', 'ta': 'எப்போது எனக்கு பணம் கிடைக்கும்?',
    },
    'faqPayoutAnswer': {
      'en': 'Once the buyer confirms delivery, your payout is released from escrow to your Farmora Wallet within 24 hours.',
      'si': 'ගැනුම්කරු බාරදීම තහවුරු කළ පසු, පැය 24ක් ඇතුළත ඔබේ ගෙවීම එස්ක්‍රෝවෙන් ඔබේ පසුම්බියට එවයි.',
      'ta': 'வாங்குபவர் டெலிவரியை உறுதிப்படுத்தியவுடன், உங்கள் கட்டணம் எஸ்க்ரோவிலிருந்து 24 மணி நேரத்தில் உங்கள் பணப்பைக்கு வரும்.',
    },
    'faqTransport': {
      'en': 'Who arranges transport?', 'si': 'ප්‍රවාහනය සකසන්නේ කවුද?', 'ta': 'போக்குவரத்து யார் ஏற்பாடு செய்கிறார்கள்?',
    },
    'faqTransportAnswer': {
      'en': 'Farmora dispatches verified 3PL logistics partners automatically. You only pack the harvest at your farm gate.',
      'si': 'Farmora සත්‍යාපිත 3PL හවුල්කරුවන් ස්වයංක්‍රීයව යවයි. ඔබ අස්වැන්න ගොවිපල දොරටුවේ දී පමණක් ඇසුරුම් කරන්න.',
      'ta': 'Farmora சரிபார்க்கப்பட்ட 3PL கூட்டாளர்களை தானாகவே அனுப்புகிறது. நீங்கள் அறுவடையை பண்ணை வாயிலில் மட்டும் பேக்கேஜ் செய்யவும்.',
    },
    'faqVerification': {
      'en': 'Why do I need verification?', 'si': 'මම ඇයි තහවුරු කිරීමට අවශ්‍ය?', 'ta': 'எனக்கு ஏன் சரிபார்ப்பு தேவை?',
    },
    'faqVerificationAnswer': {
      'en': 'Verification builds buyer trust. Verified farmers get priority placement and faster payouts.',
      'si': 'තහවුරු කිරීම ගැනුම්කරුගේ විශ්වාසය වැඩි කරයි. තහවුරු කළ ගොවීන්ට ප්‍රමුඛතාවය සහ වේගවත් ගෙවීම් ලැබේ.',
      'ta': 'சரிபார்ப்பு வாங்குபவரின் நம்பிக்கையை அதிகரிக்கிறது. சரிபார்க்கப்பட்ட விவசாயிகளுக்கு முன்னுரிமை மற்றும் வேகமான கட்டணங்கள் கிடைக்கும்.',
    },
    'callSupport': {
      'en': 'Call Support', 'si': 'සහාය අමතන්න', 'ta': 'ஆதரவை அழைக்க',
    },
    'emailUs': {
      'en': 'Email Us', 'si': 'ඊමේල් කරන්න', 'ta': 'மின்னஞ்சல் செய்யவும்',
    },
    'whatsapp': {
      'en': 'WhatsApp', 'si': 'වොට්සැප්', 'ta': 'வாட்ஸ்அப்',
    },
    'supportHours': {
      'en': 'Support hours: Mon–Sat, 8:00 AM – 6:00 PM', 'si': 'සහාය වේලාව: සඳුදා–සෙනසුරාදා, පෙ.ව. 8 – ප.ව. 6', 'ta': 'ஆதரவு நேரம்: திங்கள்–சனி, காலை 8 – மாலை 6',
    },
  };

  String get _code => switch (context.watch<FarmoraState>().language) {
        'සිංහල' => 'si',
        'தமிழ்' => 'ta',
        _ => 'en',
      };

  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[_code] ?? entry['en'] ?? key;
  }
}

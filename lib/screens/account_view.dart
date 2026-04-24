import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/supabase_auth_service.dart';
import '../services/intelligence_service.dart';
import '../services/theme_service.dart';
import '../widgets/shared.dart';
import '../services/community_service.dart';
import 'package:intl/intl.dart';
import '../services/billing_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/support_service.dart';



class AccountView extends ConsumerStatefulWidget {
  const AccountView({super.key});

  @override
  ConsumerState<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<AccountView> {
  final _sbUser = sb.Supabase.instance.client.auth.currentUser;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _phoneCtrl = TextEditingController(text: '+91 ');
  final _verifyTxnCtrl = TextEditingController();
  final _verifyAmountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedPaymentMethod = 'Bank Transfer';




  final bool _t1 = true;
  final bool _t2 = true;
  final bool _t3 = true;
  final bool _t4 = true;
  final bool _t5 = false;
  String _selectedMenu = 'PROFILE';
  bool _isNavExpanded = false; // Collapsibility state
  bool _isSidebarOpen = false; // Mobile sidebar state
  String _communityTab = 'Announcements';
  String _selectedPlan = 'Free';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;
  DateTime _selectedPaymentDate = DateTime.now();
  String _inboxTab = 'ALL (0)';
  String _supportTab = 'Active Tickets';



  @override
  void initState() {
    super.initState();
    final name = _sbUser?.email ?? 'New Trader';
    final email = _sbUser?.email ?? 'unknown@example.com';
    
    _nameCtrl = TextEditingController(text: name);
    _emailCtrl = TextEditingController(text: email);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPaymentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: gold,
              onPrimary: Colors.black,
              surface: Color(0xFF0C0704),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedPaymentDate) {
      setState(() {
        _selectedPaymentDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    // Diagnostic snackbar to confirm click
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempting to open file explorer...'), duration: Duration(seconds: 1)),
    );

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picker Error: $e')),
      );
    }
  }




  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _verifyTxnCtrl.dispose();
    _verifyAmountCtrl.dispose();
    _utrCtrl.dispose();
    _amountPaidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }



  Future<void> _saveChanges() async {
    // Supabase handles profile updates differently (via the 'users' table or auth.updateUser)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile update logic needs Supabase table setup.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Global Announcement Listener (triggers regardless of current tab)
    ref.listen(communityMessagesProvider, (previous, next) {
      if (next.hasValue && previous != null && previous.hasValue) {
        final nextMsgs = next.value!;
        final prevMsgs = previous.value!;
        if (nextMsgs.isNotEmpty && (prevMsgs.isEmpty || nextMsgs.first.id != prevMsgs.first.id)) {
          _showNewMessagePopup(nextMsgs.first);
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 850;

        if (isWide) {

          return Row(
            children: [
              _buildAccountNavigationSidebar(),
              const VerticalDivider(width: 1, thickness: 1, color: border),
              Expanded(
                child: _buildMainScrollableContent(isWide),
              ),
            ],
          );
        } else {
          return Stack(
            children: [
              Column(
                children: [
                  _buildAccountNavigationHorizontal(),
                  Expanded(
                    child: _buildMainScrollableContent(isWide),
                  ),
                ],
              ),
              if (_isSidebarOpen)
                GestureDetector(
                  onTap: () => setState(() => _isSidebarOpen = false),
                  child: Container(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              _buildSidebar(constraints.maxWidth),
            ],
          );
        }
      },
    );
  }

  Widget _buildMainScrollableContent(bool isWide) {
    return ListView(
      padding: isWide
          ? const EdgeInsets.all(24)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        if (_selectedMenu == 'PROFILE') ...[
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPersonalInfo(),
          const SizedBox(height: 20),
          _buildPreferences(),
          const SizedBox(height: 20),
          _buildDangerZone(),
        ] else if (_selectedMenu == 'ALERTS') ...[
          _buildHeader(
              customTitle: 'NOTIFICATIONS',
              customSubtitle: 'Manage how and when you receive alerts'),
          const SizedBox(height: 20),
          _buildNotifications(),
        ] else if (_selectedMenu == 'PLAN') ...[
          _buildPlan(),
        ] else if (_selectedMenu == 'HISTORY') ...[
          _buildBillingHeader(),
          const SizedBox(height: 24),
          _buildBilling(),

        ] else if (_selectedMenu == 'VERIFY') ...[
          _buildVerify(),

        ] else if (_selectedMenu == 'COMMUNITY') ...[

          _buildCommunityHeader(),
          const SizedBox(height: 24),
          _buildCommunityTabs(),
          const SizedBox(height: 24),
          _buildCommunityContent(),
        ] else if (_selectedMenu == 'HELP') ...[
          _buildSupport(),
        ],
        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  Widget _placeholderPanel(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: gold, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: themeText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(subtitle,
              style: TextStyle(
                  color: themeTextDim(context), fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAccountNavigationSidebar() {
    return GestureDetector(
      onTap: () => setState(() => _isNavExpanded = !_isNavExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 85,
        decoration: BoxDecoration(
          color: themeSurface(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...[
                _accountNavItem(Icons.people_outline, 'COMMUNITY', 'COMMUNITY'),
                _accountNavItem(Icons.shield_outlined, 'PLAN', 'PLAN'),
                _accountNavItem(Icons.receipt_long, 'HISTORY', 'HISTORY'),
                _accountNavItem(Icons.credit_card, 'VERIFY', 'VERIFY'),
                _accountNavItem(Icons.settings_outlined, 'PROFILE', 'PROFILE'),
                _accountNavItem(Icons.notifications_none, 'ALERTS', 'NOTIF'),
                _accountNavItem(Icons.help_outline, 'HELP', 'SUPPORT'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountNavigationHorizontal() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border(bottom: BorderSide(color: themeBorder(context).withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Radar Trigger Icon with Ripple Effect
          // Radar Trigger Icon with Premium Ripple & Glow Effect
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isNavExpanded = !_isNavExpanded),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isNavExpanded 
                        ? gold.withOpacity(0.15) 
                        : Colors.white.withOpacity(0.02),
                    border: Border.all(
                      color: _isNavExpanded 
                          ? gold.withOpacity(0.5) 
                          : Colors.white.withOpacity(0.05)
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _isNavExpanded ? [
                      BoxShadow(
                        color: gold.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ] : [],
                  ),
                  child: Center(
                    child: Icon(
                      _isNavExpanded ? Icons.close : Icons.account_circle_outlined, 
                      color: gold, 
                      size: 20
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isNavExpanded ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isNavExpanded,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      _accountNavItem(Icons.people_outline, 'COMMUNITY', 'COMMUNITY'),
                      _accountNavItem(Icons.shield_outlined, 'PLAN', 'PLAN'),
                      _accountNavItem(Icons.receipt_long, 'HISTORY', 'HISTORY'),
                      _accountNavItem(Icons.credit_card, 'VERIFY', 'VERIFY'),
                      _accountNavItem(Icons.settings_outlined, 'PROFILE', 'PROFILE'),
                      _accountNavItem(Icons.notifications_none, 'ALERTS', 'NOTIF'),
                      _accountNavItem(Icons.help_outline, 'HELP', 'SUPPORT'),
                      const SizedBox(width: 8),
                      // Logout in horizontal menu
                      _accountNavItem(Icons.logout, 'LOGOUT', 'LOGOUT', activeColor: const Color(0xFFFF0033)),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(double screenWidth) {
    final double sidebarWidth = screenWidth * 0.85; // Slightly wider for subtitles
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: _isSidebarOpen ? 0 : -sidebarWidth,
      top: 0,
      bottom: 0,
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: themeSurface(context),
          border: Border(right: BorderSide(color: gold.withOpacity(0.1))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            // Sidebar Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: const Row(
                children: [
                  Icon(Icons.account_circle_outlined, color: gold, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'ACCOUNT SYSTEM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(margin: const EdgeInsets.symmetric(horizontal: 24), height: 1, color: Colors.white.withOpacity(0.05)),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _sidebarSectionLabel('NETWORK'),
                    _buildSidebarItem(Icons.people_outline, 'COMMUNITY', 'Announcements & Forums'),
                    
                    const SizedBox(height: 20),
                    _sidebarSectionLabel('BILLING'),
                    _buildSidebarItem(Icons.shield_outlined, 'PLAN', 'Manage Your Plan', shortNameOverride: 'SUBSCRIPTION'),
                    _buildSidebarItem(Icons.receipt_long, 'HISTORY', 'Invoices & Records', shortNameOverride: 'PAYMENT HISTORY'),
                    _buildSidebarItem(Icons.credit_card, 'VERIFY', 'Submit Crypto TXID', shortNameOverride: 'VERIFY PAYMENT'),
                    
                    const SizedBox(height: 20),
                    _sidebarSectionLabel('PREFERENCES'),
                    _buildSidebarItem(Icons.settings_outlined, 'PROFILE', 'Security & Details', shortNameOverride: 'PROFILE SETTINGS'),
                    _buildSidebarItem(Icons.notifications_none, 'ALERTS', 'Alert Preferences', shortNameOverride: 'NOTIFICATIONS'),
                    _buildSidebarItem(Icons.help_outline, 'HELP', 'Help Tickets', shortNameOverride: 'SUPPORT'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildSidebarLogout(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(
        label,
        style: TextStyle(
          color: themeTextDim(context).withOpacity(0.5),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String moduleId, String subtitle, {String? shortNameOverride}) {
    final bool isSelected = _selectedMenu == moduleId;
    final String title = shortNameOverride ?? moduleId;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMenu = moduleId;
          _isSidebarOpen = false;
        }),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? gold.withOpacity(0.05) : Colors.transparent,
            border: Border.all(
              color: isSelected ? gold.withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? gold : themeText(context).withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? gold : Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? gold.withOpacity(0.6) : themeTextDim(context).withOpacity(0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarLogout() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await SupabaseAuthService.signOut();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0033).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFFF0033).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.logout, color: Color(0xFFFF0033), size: 16),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'LOGOUT',
                style: TextStyle(
                  color: Color(0xFFFF0033),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountNavItem(IconData icon, String title, String shortName, {Color activeColor = gold}) {
    final bool isSelected = _selectedMenu == title;
    final bool isLogout = title == 'LOGOUT';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (isLogout) {
            await SupabaseAuthService.signOut();
          } else {
            setState(() {
              _selectedMenu = title;
              _isNavExpanded = false; // Collapse on choice
            });
          }
        },
        child: Container(
          width: 80,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected || isLogout
                      ? activeColor.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected || isLogout
                        ? activeColor.withOpacity(0.6)
                        : Colors.white.withOpacity(0.02),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: (isSelected || isLogout) ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected || isLogout 
                        ? activeColor 
                        : themeText(context).withOpacity(0.40),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (isSelected || isLogout || _isNavExpanded) ? 1.0 : 0.0,
                  child: Text(
                    shortName,
                    style: TextStyle(
                      color: isSelected || isLogout ? activeColor : themeTextDim(context).withOpacity(0.35),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      {String customTitle = 'PROFILE & SETTINGS',
      String customSubtitle = 'Manage your account preferences'}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: themeSection(context).withOpacity(0.5),
            border: Border.all(color: gold.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person_outline, color: gold, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customTitle,
                  style: TextStyle(
                      color: themeText(context),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(customSubtitle,
                  style: TextStyle(
                      color: themeTextDim(context).withOpacity(0.6),
                      fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardWrapper(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gold, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: themeText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _cardWrapper(
      icon: Icons.person_outline,
      title: 'PERSONAL INFORMATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _inputField('FULL NAME', _nameCtrl, null, readOnly: false),
          const SizedBox(height: 16),
          _inputField('EMAIL ADDRESS', _emailCtrl, _zeroBadge(),
              readOnly: true),
          const SizedBox(height: 16),
          _inputField('Phone Number', _phoneCtrl, _indiaFlag(),
              isPrefix: true, readOnly: false),
          const SizedBox(height: 24),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _saveChanges,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SAVE CHANGES',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: gold.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('ZERO',
          style: TextStyle(
              color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _indiaFlag() {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: const Text('🇮🇳', style: TextStyle(fontSize: 14)),
    );
  }

  Widget _buildCommunityHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeSection(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gold.withOpacity(0.1)),
              ),
              child: const Icon(Icons.people_alt_outlined, color: gold, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMMUNITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Connect and learn from the trading community',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommunityTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeBorder(context).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _communityTabItem('Announcements', Icons.campaign_outlined),
          _communityTabItem('Live Chat', Icons.chat_bubble_outline),
          _communityTabItem('Community Forum', Icons.forum_outlined),
        ],
      ),
    );
  }

  Widget _communityTabItem(String label, IconData icon) {
    final bool isActive = _communityTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _communityTab = label),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? gold.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: gold.withOpacity(0.3)) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? gold : themeTextDim(context), size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? gold : themeTextDim(context),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCommunityContent() {
    if (_communityTab == 'Announcements') {
      return _buildAnnouncementsView();
    } else if (_communityTab == 'Live Chat') {
      return _buildChatView();
    } else {
      return _buildForumView();
    }
  }

  Widget _buildAnnouncementsView() {
    final messagesAsync = ref.watch(communityMessagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_outlined, color: gold, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Important Updates',
                  style: TextStyle(
                    color: themeText(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeSection(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: themeTextDim(context).withOpacity(0.2)),
              ),
              child: const Text(
                'OFFICIAL SOURCE',
                style: TextStyle(
                   color: gold,
                   fontSize: 9,
                   fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) {
              return _buildMessageCard(CommunityMessage(
                id: 'welcome',
                title: 'Welcome to D Trade Capital',
                content: "You're now part of the early access version of our behavioral AI engine.\n\nThis platform is built to help traders understand and improve execution discipline through real-time behavioral analysis.\n\nExplore the current features, experience how the system evaluates trading behavior, and stay tuned — View Mode with AI behavioral statistics is coming soon.\n\nWe're building this with our early users. Your feedback matters.\n\nLet's build disciplined trading together.",
                type: 'ALL',
                createdAt: DateTime(2026, 3, 2, 9, 5, 35),
              ));
            }
            return Column(
              children: messages.map((m) => _buildMessageCard(m)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: gold)),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: themeTextDim(context)))),
        ),
      ],
    );

  }

  Widget _buildChatView() {
    return _comingSoonCard(
      title: 'Live Chat',
      icon: Icons.chat_bubble_outline,
      subtitle: 'This feature is currently under development. Stay tuned for updates!',
    );
  }

  Widget _buildForumView() {
    return _comingSoonCard(
      title: 'Community Forum',
      icon: Icons.forum_outlined,
      subtitle: 'This feature is currently under development. Stay tuned for updates!',
    );
  }

  Widget _comingSoonCard({required String title, required IconData icon, required String subtitle}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        decoration: BoxDecoration(
          color: themeSection(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeBorder(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(icon, color: gold, size: 32),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                color: themeText(context),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit', // Or any premium font available
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeTextDim(context).withOpacity(0.6),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: gold.withOpacity(0.3)),
                color: gold.withOpacity(0.05),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMessageCard(CommunityMessage message) {

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.05),
                  border: Border.all(color: gold.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  message.type.toUpperCase(),
                  style: const TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                DateFormat('M/d/yyyy, h:mm:ss a').format(message.createdAt),
                style: TextStyle(color: themeTextDim(context).withOpacity(0.3), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message.title,
            style: TextStyle(
              color: themeText(context),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message.content,
            style: TextStyle(
              color: themeTextDim(context).withOpacity(0.8),
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '— Team D Trade Capital',
            style: TextStyle(
              color: themeTextDim(context).withOpacity(0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewMessagePopup(CommunityMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0704),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gold.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: gold,
                radius: 12,
                child: Icon(Icons.notifications_active, color: Colors.black, size: 14),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEW ANNOUNCEMENT',
                      style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      message.title,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedMenu = 'COMMUNITY'),
                child: const Text('VIEW', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, Widget? extra,

      {bool isPrefix = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: themeTextDim(context),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: themeSection(context),
            border: Border.all(color: themeBorder(context)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (isPrefix && extra != null) ...[
                extra,
                const SizedBox(width: 8),
                Icon(Icons.arrow_drop_down,
                    color: themeTextDim(context).withOpacity(0.7), size: 16),
                const SizedBox(width: 8)
              ],
              Expanded(
                child: TextField(
                  controller: ctrl,
                  readOnly: readOnly,
                  style: TextStyle(
                      color: readOnly ? themeTextDim(context) : themeText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (!isPrefix && extra != null) extra,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInboxHeader(),
        const SizedBox(height: 32),
        _buildInboxContent(),
      ],
    );
  }

  Widget _buildInboxHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(Icons.notifications_none_outlined, color: gold, size: 24),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR INBOX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // Reduced from 22
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.2,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'Systems clear, no new alerts',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInboxContent() {
    final user = sb.Supabase.instance.client.auth.currentUser;
    final alertsAsync = user != null ? ref.watch(userAlertsProvider(user.id)) : const AsyncValue.data([]);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeBorder(context)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildInboxTabs(),
          const SizedBox(height: 48),
          alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty || _inboxTab != 'ALL (0)') {
                return _buildInboxEmptyState();
              }
              return Column(
                children: alerts.map((a) => _alertItem(a)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: gold)),
            error: (err, _) => _buildInboxEmptyState(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildInboxTabs() {
    final user = sb.Supabase.instance.client.auth.currentUser;
    final alertsCount = user != null ? ref.watch(userAlertsProvider(user.id)).maybeWhen(data: (d) => d.length, orElse: () => 0) : 0;
    
    final tabs = ['ALL ($alertsCount)', 'UNREAD (0)', 'SUPPORT', 'PAYMENTS', 'SIGNALS'];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeBorder(context).withOpacity(0.5)),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = t == _inboxTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _inboxTab = t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  t,
                  style: TextStyle(
                    color: isSelected ? Colors.black : themeTextDim(context).withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInboxEmptyState() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold.withOpacity(0.1), width: 2),
            color: gold.withOpacity(0.02),
          ),
          child: Icon(Icons.campaign_outlined, color: gold.withOpacity(0.2), size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'SYSTEM SILENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'YOUR INBOX IS CURRENTLY CLEAR.\nRELEVANT ALERTS AND SYSTEM UPDATES\nWILL BE DISPATCHCHED HERE.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: themeTextDim(context).withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.8,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _alertItem(dynamic alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.05),
        border: Border.all(color: gold.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(alert['type']?.toString().toUpperCase() ?? 'INFO',
                  style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(alert['time'] ?? 'Just now', style: TextStyle(color: themeTextDim(context), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert['message'] ?? 'No message content',
              style: TextStyle(color: themeText(context), fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _toggleRow(
      String title, String subtitle, bool isActive, VoidCallback onTap,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: themeText(context),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: themeTextDim(context), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    alignment:
                        isActive ? Alignment.centerRight : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isActive ? gold : themeBorder(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: border),
          ]
        ],
      ),
    );
  }

  Widget _buildBillingHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        return Row(
          crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildHeader(
                customTitle: 'BILLING & PAYMENTS',
                customSubtitle: 'Manage your subscription and track payment history.',
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 24),
              _verifyPaymentButton(),
            ],
          ],
        );
      },
    );
  }

  Widget _verifyPaymentButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showVerifyPaymentDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gold, gold.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ALREADY PAID? VERIFY YOUR PAYMENT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: Colors.black, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerifyPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0C0704),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: gold.withOpacity(0.2))),
          title: const Text('VERIFY TRANSACTION',
              style: TextStyle(color: gold, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField('TRANSACTION ID', _verifyTxnCtrl, null),
              const SizedBox(height: 16),
              _inputField('AMOUNT PAID', _verifyAmountCtrl, null),
              const SizedBox(height: 24),
              const Text(
                'Verification takes 1-2 hours. Please ensure the transaction ID is correct.',
                style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: themeTextDim(context), fontSize: 12)),
            ),
            GestureDetector(
              onTap: () async {
                final txn = _verifyTxnCtrl.text.trim();
                final amount = _verifyAmountCtrl.text.trim();
                if (txn.isEmpty || amount.isEmpty) return;
                
                final success = await ref.read(billingServiceProvider).requestPaymentVerification(txn, amount);
                if (mounted) Navigator.pop(context);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification request submitted successfully.')),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(8)),
                child: const Text('SUBMIT REQUEST', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildBilling() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        
        if (isNarrow) {
          return Column(
            children: [
              _planStatsCard(),
              const SizedBox(height: 24),
              _paymentHistoryCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _planStatsCard()),
            const SizedBox(width: 24),
            Expanded(flex: 7, child: _paymentHistoryCard()),
          ],
        );
      }
    );
  }

  Widget _planStatsCard() {
    final subAsync = ref.watch(userSubscriptionProvider);

    return subAsync.when(
      data: (sub) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeSection(context).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBadge('${sub.planName} PLAN', gold.withOpacity(0.1), gold),
                const SizedBox(width: 8),
                _statusBadge('STANDARD', themeBorder(context), themeTextDim(context)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sub.planName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, color: themeTextDim(context).withOpacity(0.4), size: 12),
                const SizedBox(width: 6),
                Text(
                  'EXPIRY: ${sub.expiryDate ?? 'N/A'}',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(height: 1, color: themeBorder(context).withOpacity(0.3)),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'ACCOUNT AUDIT IDENTIFIER',
                style: TextStyle(
                  color: gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeBorder(context).withOpacity(0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                sub.auditId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),

      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Error loading status: $e')),
    );
  }


  Widget _paymentHistoryCard() {
    final historyAsync = ref.watch(paymentHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeBorder(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: gold, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'PAYMENT HISTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              historyAsync.when(
                data: (list) => Text(
                  '${list.length} RECORDS',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                loading: () => const SizedBox(),
                error: (e, s) => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: themeBorder(context).withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            children: [
              _tableHeading('DATE'),
              _tableHeading('PLAN'),
              _tableHeading('AMOUNT'),
              _tableHeading('METHOD'),
              _tableHeading('STATUS'),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: themeBorder(context).withOpacity(0.1)),
          
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: themeTextDim(context).withOpacity(0.1), size: 24),
                        const SizedBox(height: 12),
                        Text(
                          'NO PAYMENT RECORDS YET.',
                          style: TextStyle(
                            color: themeTextDim(context).withOpacity(0.2),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: records.map((r) => _paymentRow(r)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'PAYMENT SYSTEM OFFLINE',
                  style: TextStyle(color: gold.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


  Widget _paymentRow(PaymentHistory record) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              _tableCell(record.date),
              _tableCell(record.plan),
              _tableCell('\$${record.amount}'),
              _tableCell(record.method),
              _tableCell(record.status, color: record.status == 'COMPLETED' ? const Color(0xFF00FF66) : gold),
            ],
          ),
        ),
        Container(height: 1, color: themeBorder(context).withOpacity(0.05)),
      ],
    );
  }

  Widget _tableCell(String text, {Color? color}) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(
          color: color ?? themeTextDim(context).withOpacity(0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _tableHeading(String text) {
    return Expanded(
      child: Text(
        text,
        style: TextStyle(
          color: themeTextDim(context).withOpacity(0.3),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


  Widget _buildPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
            customTitle: 'MY SUBSCRIPTION',
            customSubtitle: 'Manage your plan and billing'),
        const SizedBox(height: 24),
        _activePlanBanner(),
        const SizedBox(height: 32),
        _buildPlanTabs(),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            if (isNarrow) {
              // Mobile/Tablet: Show only the selected plan
              if (_selectedPlan == 'Free') {
                return _planCard(
                  title: 'ZERO',
                  price: 'Free',
                  description: 'Get started with AI-powered insights. Perfect for: Curious traders who want to test the platform.',
                  features: ['3 AI-powered signals per week', 'Community access (Telegram/Discord)', 'Basic market analysis (weekly recap)', 'Trading psychology mini-course (5 lessons)', 'Risk calculator tool'],
                  icon: Icons.shield_outlined,
                );
              } else if (_selectedPlan == 'Core') {
                return _planCard(
                  title: 'CORE',
                  price: '\$9',
                  description: 'AI-powered self-awareness for your trading.',
                  features: ['Trader Genome™ — Full Profile unlocked', 'Weekly behavioral report (pattern breakdown, risk trends, discipline score)', 'EVI history & session tracking', 'Emotional pattern detection (revenge loops, FOMO cycles, size drift)', 'Behavioral Fitness Score — weekly progress', 'Email support'],
                  icon: Icons.bolt_outlined,
                  badge: 'SAVE 60% OFF',
                );
              } else {
                return _planCard(
                  title: 'GUARDIAN',
                  price: '\$29',
                  description: 'Real-time AI protection for your capital.',
                  features: ['Everything in Core', 'Real-time behavioral intervention (hard blocks)', 'Destruction sequence prediction', 'Emotional Volatility Index — live dashboard', 'Revenge trade auto-detection & block', 'Position size cap enforcement', 'Loss streak auto-shutdown', 'Full AI Guardian — Behavioral Shield active', 'Performance analytics dashboard', 'Priority support (12hr response)'],
                  icon: Icons.workspace_premium_outlined,
                  isPopular: true,
                  badge: 'SAVE 66% OFF',
                );
              }
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child:  _planCard(
                    title: 'ZERO',
                    price: 'Free',
                    description: 'Get started with AI-powered insights. Perfect for: Curious traders who want to test the platform.',
                    features: ['3 AI-powered signals per week', 'Community access (Telegram/Discord)', 'Basic market analysis (weekly recap)', 'Trading psychology mini-course (5 lessons)', 'Risk calculator tool'],
                    icon: Icons.shield_outlined,
                    isActive: _selectedPlan == 'Free',
                  )),
                const SizedBox(width: 24),
                Expanded(child: _planCard(
                    title: 'CORE',
                    price: '\$9',
                    description: 'AI-powered self-awareness for your trading.',
                    features: ['Trader Genome™ — Full Profile unlocked', 'Weekly behavioral report (pattern breakdown, risk trends, discipline score)', 'EVI history & session tracking', 'Emotional pattern detection (revenge loops, FOMO cycles, size drift)', 'Behavioral Fitness Score — weekly progress', 'Email support'],
                    icon: Icons.bolt_outlined,
                    badge: 'SAVE 60% OFF',
                    isActive: _selectedPlan == 'Core',
                  )),
                const SizedBox(width: 24),
                Expanded(child: _planCard(
                    title: 'GUARDIAN',
                    price: '\$29',
                    description: 'Real-time AI protection for your capital.',
                    features: ['Everything in Core', 'Real-time behavioral intervention (hard blocks)', 'Destruction sequence prediction', 'Emotional Volatility Index — live dashboard', 'Revenge trade auto-detection & block', 'Position size cap enforcement', 'Loss streak auto-shutdown', 'Full AI Guardian — Behavioral Shield active', 'Performance analytics dashboard', 'Priority support (12hr response)'],
                    icon: Icons.workspace_premium_outlined,
                    isPopular: true,
                    badge: 'SAVE 66% OFF',
                    isActive: _selectedPlan == 'Guardian',
                  )),
              ],
            );
          },
        ),

        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Text('SECURE PAYMENTS VIA STRIPE & PAYPAL', 
                   style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('CANCEL ANYTIME - 24H VERIFICATION', 
                   style: TextStyle(color: themeTextDim(context).withOpacity(0.2), fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activePlanBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isVeryNarrow = constraints.maxWidth < 500;
        final bool isCompact = constraints.maxWidth < 700;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24, vertical: 20),
          decoration: BoxDecoration(
            color: themeSection(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeBorder(context)),
          ),
          child: Row(
            children: [
              if (!isVeryNarrow) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeBorder(context)),
                  ),
                  child: const Icon(Icons.credit_card, color: gold, size: 24),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _statusBadge('ZERO', gold.withOpacity(0.1), gold),
                        const SizedBox(width: 8),
                        _statusBadge('ACTIVE', const Color(0xFF00FF66).withOpacity(0.1), const Color(0xFF00FF66)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ZERO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'EXPIRY: CONTACT ADMIN',
                      style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ACTIVE', style: TextStyle(color: Color(0xFF00FF66), fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                    Text('STATUS', style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('24/7', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                    Text('SUPPORT', style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00FF66).withOpacity(0.3)),
                    color: const Color(0xFF00FF66).withOpacity(0.05),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Color(0xFF00FF66), size: 14),
                      SizedBox(width: 8),
                      Text(
                        'PLAN ACTIVE',
                        style: TextStyle(color: Color(0xFF00FF66), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }





  Widget _statusBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlanTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeBorder(context)),
      ),
      child: Row(
        children: [
          _planTabItem('Free', Icons.shield_outlined),
          _planTabItem('Core', Icons.bolt_outlined),
          _planTabItem('Guardian', Icons.workspace_premium_outlined),
        ],
      ),
    );
  }

  Widget _planTabItem(String label, IconData icon) {
    final bool isActive = _selectedPlan == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = label),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? gold.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: gold.withOpacity(0.3)) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? gold : themeTextDim(context).withOpacity(0.5), size: 14),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? gold : themeTextDim(context).withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required IconData icon,
    String? badge,
    bool isPopular = false,
    bool isActive = false,
  }) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isPopular ? gold.withOpacity(0.05) : themeSection(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? gold : (isPopular ? gold.withOpacity(0.3) : themeBorder(context))),
            boxShadow: isActive ? [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 20, spreadRadius: 0)] : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isPopular)
                Positioned(
                  top: -34,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFE6D4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('MOST POPULAR', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              if (badge != null)
                 Positioned(
                  top: -36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF66),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPopular ? gold : Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: gold.withOpacity(0.2)),
                      ),
                      child: Icon(icon, color: isPopular ? Colors.black : gold, size: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'serif',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: themeTextDim(context).withOpacity(0.6), fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      if (price != 'Free') 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0, left: 4),
                          child: Text('/MONTH', style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (price == '\$9')
                    Center(child: Text('BILLED \$108 ANNUALLY', style: TextStyle(color: themeTextDim(context).withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold))),
                  if (price == '\$29')
                    Center(child: Text('BILLED \$348 ANNUALLY', style: TextStyle(color: themeTextDim(context).withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold))),
                  
                  const SizedBox(height: 24),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: gold, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(color: themeTextDim(context).withOpacity(0.8), fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      if (isActive) return;
                      final success = await ref.read(billingServiceProvider).buyPlan(title, price);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: gold,
                            content: Text(
                              'UPGRADE REQUEST FOR $title SUBMITTED',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: title == 'GUARDIAN' ? (isActive ? const Color(0xFFEFE6D4) : const Color(0xFFEFE6D4).withOpacity(0.6)) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gold.withOpacity(0.5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isActive ? 'CURRENT PLAN' : 'SELECT $title',
                          style: TextStyle(
                            color: title == 'GUARDIAN' ? Colors.black : gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }




  Widget _billingBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: themeSection(context),
        border: Border.all(color: themeBorder(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: themeTextDim(context),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: themeText(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildPreferences() {
    return _cardWrapper(
      icon: Icons.language,
      title: 'PREFERENCES',
      child: Row(
        children: [
          Expanded(child: _dropdownBase('Language', 'English')),
          const SizedBox(width: 8),
          Expanded(child: _dropdownBase('Time Zone', '')),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.themeModeNotifier,
                builder: (context, mode, _) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        ThemeService.setTheme(mode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark);
                      },
                      child: _dropdownBase('Theme Mode',
                          mode == ThemeMode.dark ? 'Dark' : 'Light'),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _dropdownBase(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: themeTextDim(context), fontSize: 11)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: themeSection(context),
            border: Border.all(color: themeBorder(context)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: TextStyle(
                      color: themeText(context),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down,
                  color: themeTextDim(context).withOpacity(0.7), size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupportHeader(),
        const SizedBox(height: 32),
        _buildSupportStats(),
        const SizedBox(height: 32),
        _buildSupportMainContent(),
      ],
    );
  }

  Widget _buildSupportHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUPPORT & TICKETS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18, // Reduced from 22
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.2,
              ),
            ),
            Row(
              children: [
                Text(
                  'Management Portal',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFF00FF66), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: TextStyle(
                    color: themeTextDim(context).withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        _newTicketButton(),
      ],
    );
  }

  Widget _newTicketButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showNewTicketDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [gold, gold.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 10)],
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: Colors.black, size: 12), // Shrunk 16->12
              SizedBox(width: 6),
              Text(
                'NEW TICKET',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 9, // Shrunk 10->9
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportStats() {
    final ticketsAsync = ref.watch(userTicketsProvider);
    
    return ticketsAsync.when(
      data: (tickets) {
        final activeCount = tickets.where((t) => t.status == 'OPEN').length;
        final resolvedCount = tickets.where((t) => t.status == 'RESOLVED' || t.status == 'CLOSED').length;
        
        return Row(
          children: [
            Expanded(child: _supportStatCard('Active Tickets', '$activeCount', Icons.warning_amber_rounded, gold)),
            const SizedBox(width: 16),
            Expanded(child: _supportStatCard('Resolved', '$resolvedCount', Icons.check_circle_outline, const Color(0xFF00FF66))),
            const SizedBox(width: 16),
            Expanded(child: _supportStatCard('Response Time', '< 2h', Icons.access_time, gold, subtitle: 'Average help time')),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _supportStatCard(String title, String value, IconData icon, Color color, {String? subtitle, double? width}) {
    final bool isActive = _supportTab == title;
    return GestureDetector(
      onTap: () => setState(() => _supportTab = title),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.05) : themeSection(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? color : themeBorder(context)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: themeTextDim(context).withOpacity(0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle.toUpperCase(),
                      style: TextStyle(
                        color: themeTextDim(context).withOpacity(0.2),
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 900;
        
        if (isNarrow) {
          return Column(
            children: [
              _buildTicketList(),
              const SizedBox(height: 24),
              _buildTicketPlaceholder(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _buildTicketList()),
            const SizedBox(width: 24),
            Expanded(flex: 6, child: _buildTicketPlaceholder()),
          ],
        );
      }
    );
  }

  Widget _buildTicketList() {
    final ticketsAsync = ref.watch(userTicketsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR TICKETS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 20),
        ticketsAsync.when(
          data: (tickets) {
            final filtered = tickets.where((t) {
              if (_supportTab == 'Active Tickets') return t.status == 'OPEN';
              if (_supportTab == 'Resolved') return t.status == 'RESOLVED' || t.status == 'CLOSED';
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeBorder(context).withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: themeTextDim(context).withOpacity(0.1), size: 28),
                    const SizedBox(height: 12),
                    Text(
                      'NO TICKETS FOUND',
                      style: TextStyle(color: themeTextDim(context).withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filtered.map((t) => _buildTicketItem(t)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: gold)),
          error: (e, s) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildTicketItem(SupportTicket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeBorder(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: gold.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.message_outlined, color: gold, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ticket.category, style: TextStyle(color: themeTextDim(context).withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ticket.status == 'OPEN' ? gold.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ticket.status,
              style: TextStyle(color: ticket.status == 'OPEN' ? gold : Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketPlaceholder() {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeBorder(context).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withOpacity(0.02),
              border: Border.all(color: gold.withOpacity(0.1)),
            ),
            child: Icon(Icons.headphones_outlined, color: gold.withOpacity(0.1), size: 32),
          ),
          const SizedBox(height: 24),
          const Text(
            'TICKET DETAILS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'SELECT A TICKET FROM THE LIST\nTO VIEW CONVERSATION HISTORY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeTextDim(context).withOpacity(0.2),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegal() {
    return _cardWrapper(
      icon: Icons.description_outlined,
      title: 'LEGAL',
      child: Column(
        children: [
          _legalRow('Terms & Conditions'),
          _legalRow('Privacy Policy'),
          _legalRow('Refund Policy', isLast: true),
        ],
      ),
    );
  }

  Widget _legalRow(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text,
              style: TextStyle(
                  color: themeText(context),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Icon(Icons.arrow_forward_ios,
              color: themeTextDim(context).withOpacity(0.7), size: 14),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSurface(context),
        border: Border.all(color: const Color(0xFFFF0033).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: TextStyle(
              color: themeText(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    await SupabaseAuthService.signOut();
                  },
                  child: _dangerBtn('Logout', false, icon: Icons.logout),
                ),
              ),
              _dangerBtn('Cancel Subscription', false),
              _dangerBtn('Delete Account', true, icon: Icons.delete_outline),
            ],
          ),
          const SizedBox(height: 16),
          Text(
              'Warning: Deleting your account is permanent and cannot be undone.',
              style: TextStyle(color: themeTextDim(context), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dangerBtn(String label, bool isSolid, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSolid ? const Color(0xFFFF0033) : Colors.transparent,
        border: Border.all(color: const Color(0xFFFF0033)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                color: isSolid ? Colors.white : const Color(0xFFFF0033),
                size: 16),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: TextStyle(
                  color: isSolid ? Colors.white : const Color(0xFFFF0033),
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildVerify() {
    final statusAsync = ref.watch(verificationStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == 'UNDER REVIEW') {
          return _statusPanel(
            'UNDER REVIEW', 
            'Your audit request is currently being processed by our compliance team.',
            Icons.history,
            gold,
          );
        } else if (status == 'COMPLETED') {
          return _statusPanel(
            'SUCCESSFUL', 
            'Verification successful. Your account tiers have been updated.',
            Icons.check_circle_outline,
            const Color(0xFF00FF66),
          );
        }
        return _buildVerifyForm();
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => _buildVerifyForm(), // Fallback to form if error
    );
  }

  Widget _statusPanel(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: themeSection(context).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: themeTextDim(context), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 32),
            if (title == 'SUCCESSFUL')
              GestureDetector(
                onTap: () => setState(() => _selectedMenu = 'PLAN'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: const Text('BACK TO PLANS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedMenu = 'PLAN'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: themeTextDim(context).withOpacity(0.4), size: 14),
                const SizedBox(width: 8),
                Text('BACK TO PLANS', style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'VALIDATE AUDIT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'STEP 2: PROOF OF TRANSACTION SUBMISSION',
          style: TextStyle(color: themeTextDim(context).withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 32),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _paymentMethodDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _inputField('AMOUNT (\$) (REQUIRED)', _amountPaidCtrl, null)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _inputField('UTR / TRANSACTION ID (REQUIRED)', _utrCtrl, const Icon(Icons.receipt_outlined, color: Colors.white24, size: 14)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectDate,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AbsorbPointer(
                            child: _inputField('DATE OF PAYMENT (REQUIRED)', TextEditingController(text: DateFormat('MM/dd/yyyy').format(_selectedPaymentDate)), const Icon(Icons.calendar_today, color: gold, size: 14), readOnly: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _uploadBox(),
                      const SizedBox(height: 24),
                      _notesArea(),
                      const SizedBox(height: 32),
                      _submitVerifyBtn(),
                    ],

                  ),
                ),
                if (!isNarrow) ...[
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _whyAuditCard(),
                        const SizedBox(height: 24),
                        _rulesCard(),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _paymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT METHOD', style: TextStyle(color: themeTextDim(context), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: themeSection(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeBorder(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPaymentMethod,
              dropdownColor: const Color(0xFF0C0704),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              items: ['Bank Transfer', 'Stripe', 'PayPal', 'Crypto (USDT)']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AUDIT SCREENSHOT (REQUIRED - MAX 5MB)', style: TextStyle(color: themeTextDim(context), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              splashColor: gold.withOpacity(0.1),
              highlightColor: gold.withOpacity(0.05),
              child: Ink(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: themeSection(context).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _selectedImageBytes != null ? gold : gold.withOpacity(0.2)),
                image: _selectedImageBytes != null 
                  ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover, opacity: 0.5)
                  : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedImageBytes != null ? Icons.check_circle_outline : Icons.unarchive_outlined, 
                    color: _selectedImageBytes != null ? gold : themeTextDim(context).withOpacity(0.2), 
                    size: 28
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedImageBytes != null ? 'CHANGE SCREENSHOT' : 'CLICK TO UPLOAD PROOF', 
                    style: TextStyle(
                      color: _selectedImageBytes != null ? gold : themeTextDim(context).withOpacity(0.4), 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1
                    )
                  ),
                  if (_selectedImageName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_selectedImageName!, style: TextStyle(color: gold.withOpacity(0.5), fontSize: 8)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }


  Widget _notesArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADDITIONAL NOTES (OPTIONAL)', style: TextStyle(color: themeTextDim(context), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeSection(context).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeBorder(context)),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Any other details for our auditors...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitVerifyBtn() {
    return GestureDetector(
      onTap: () async {
        if (_isUploading) return;
        
        final utr = _utrCtrl.text.trim();
        final amount = _amountPaidCtrl.text.trim();
        if (utr.isEmpty || amount.isEmpty || _selectedImageBytes == null) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('ALL FIELDS ARE REQUIRED including the Audit Screenshot.'))
           );
           return;
        }

        setState(() => _isUploading = true);

        final success = await ref.read(billingServiceProvider).submitVerification(
          method: _selectedPaymentMethod,
          amount: amount,
          utr: utr,
          date: DateFormat('yyyy-MM-dd').format(_selectedPaymentDate),
          notes: _notesCtrl.text.trim(),
          imageBytes: _selectedImageBytes,
          imageName: _selectedImageName,
        );

        setState(() => _isUploading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AUDIT SUBMITTED FOR REVIEW')),
          );
          // Clear form
          _utrCtrl.clear();
          _amountPaidCtrl.clear();
          _notesCtrl.clear();
          setState(() {
            _selectedImageBytes = null;
            _selectedImageName = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission failed. Please check your connection.')),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [gold, gold.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: gold.withOpacity(0.1), blurRadius: 15)],
        ),
        alignment: Alignment.center,
        child: _isUploading 
          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
          : const Text('SUBMIT FOR VERIFICATION', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      ),
    );
  }

  Widget _whyAuditCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeSection(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.verified_user_outlined, color: gold, size: 20),
          ),
          const SizedBox(height: 16),
          const Text(
            'WHY AUDIT?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'serif',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To protect the ecosystem and ensure genuine trade signals, we manually audit every transaction. Verification typically takes less than 24 hours.',
            style: TextStyle(color: themeTextDim(context).withOpacity(0.6), fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              const Text('ATTEMPTS LEFT: 3 / 3', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUBMISSION RULES', style: TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _ruleItem('MAX 5MB SCREENSHOT'),
          const SizedBox(height: 10),
          _ruleItem('REFERENCE ID MUST BE LEGIBLE'),
          const SizedBox(height: 10),
          _ruleItem('ONE TRANSACTION PER SUBMISSION'),
        ],
      ),
    );
  }


  void _showNewTicketDialog() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'PAYMENT';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0704),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CREATE NEW TICKET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Category
                const Text('CATEGORY', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      dropdownColor: const Color(0xFF0C0704),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: ['PAYMENT', 'SIGNAL', 'TECHNICAL', 'OTHER']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Subject
                const Text('SUBJECT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Brief summary of your issue',
                    hintStyle: const TextStyle(color: Colors.white10),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text('DESCRIPTION', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Detailed explanation...',
                    hintStyle: const TextStyle(color: Colors.white10),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (subjectCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                          setDialogState(() => isSubmitting = true);
                          
                          final success = await ref.read(supportServiceProvider).createTicket(
                            subjectCtrl.text.trim(),
                            category,
                            descCtrl.text.trim(),
                          );
                          
                          if (success) {
                            ref.invalidate(userTicketsProvider);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('TICKET CREATED SUCCESSFULLY')),
                            );
                          } else {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('FAILED TO CREATE TICKET')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: isSubmitting 
                            ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('SUBMIT TICKET', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, color: gold, size: 6),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: themeTextDim(context).withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}


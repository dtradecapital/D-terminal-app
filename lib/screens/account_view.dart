import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AccountViewState extends ConsumerState<AccountView> with TickerProviderStateMixin {
  final _sbUser = sb.Supabase.instance.client.auth.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final GlobalKey _freeCardKey = GlobalKey();
  final GlobalKey _coreCardKey = GlobalKey();
  final GlobalKey _guardianCardKey = GlobalKey();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  
  // Security controllers
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  // Billing/Verification controllers
  final _verifyTxnCtrl = TextEditingController();
  final _verifyAmountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  final _amountPaidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  // UI State variables
  String _selectedPaymentMethod = 'Bank Transfer';
  String _selectedMenu = 'PROFILE';
  bool _isNavExpanded = false;
  bool _isSidebarOpen = false;
  String _communityTab = 'Announcements';
  String _selectedPlan = 'Free';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;
  DateTime _selectedPaymentDate = DateTime.now();
  String _inboxTab = 'ALL (0)';
  String _supportTab = 'Active Tickets';

  // New Profile / Security / Preferences state
  double _xpProgress = 3450.0;
  final double _maxXp = 5000.0;
  int _userLevel = 12;
  bool _is2FAEnabled = false;
  bool _show2FASetup = false;
  bool _isChangingPassword = false;
  late AnimationController _pulseController;
  
  // Aligned Profile Settings state
  bool _notifBroadcast = true;
  bool _notifSupport = true;
  bool _notifSignal = true;
  bool _notifPayment = true;
  bool _notifPush = false;
  String _prefLanguage = 'English';
  String _prefTimeZone = 'UTC-5 (EST)';
  String _prefTheme = 'Dark';
  
  // Notification states
  bool _notifTradeAlerts = true;
  bool _notifExecutionAlerts = true;
  bool _notifSystemStatus = false;
  bool _notifMarketing = false;

  // Developer settings
  bool _devDebugMode = false;
  bool _devVerboseTelemetry = false;
  bool _devMockSignals = false;

  // Alerts notification state
  List<Map<String, String>>? _allAlerts;

  // Mock Active Sessions
  final List<Map<String, dynamic>> _activeSessions = [
    {
      'id': '1',
      'device': 'iPhone 15 Pro Max (dTrade App)',
      'ip': '192.168.1.105',
      'location': 'Mumbai, IN',
      'lastActive': 'Active Now',
      'isCurrent': true,
    },
    {
      'id': '2',
      'device': 'Chrome / macOS 14.4',
      'ip': '103.88.22.141',
      'location': 'Singapore',
      'lastActive': '2 hours ago',
      'isCurrent': false,
    },
    {
      'id': '3',
      'device': 'iPad Terminal v1.2',
      'ip': '172.56.21.99',
      'location': 'New York, US',
      'lastActive': '3 days ago',
      'isCurrent': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    final name = _sbUser?.email?.split('@').first.toUpperCase() ?? 'ELITE TRADER';
    final email = _sbUser?.email ?? 'unknown@example.com';
    _nameCtrl = TextEditingController(text: name);
    _emailCtrl = TextEditingController(text: email);

    // Initialize mock alerts
    _allAlerts = [
      {
        'category': 'SYSTEM',
        'title': 'LEDGER AUDIT COMPLETED',
        'content': 'Platform ledger hash verification passed. Zero discrepancies found across all accounts.',
        'time': '10 minutes ago',
        'type': 'audit',
        'isRead': 'false',
      },
      {
        'category': 'SYSTEM',
        'title': 'DEPOSIT SUCCESSFUL',
        'content': 'Your deposit of 0.25 BTC has been confirmed on-chain and credited to your ledger.',
        'time': '2 hours ago',
        'type': 'billing',
        'isRead': 'true',
      },
      {
        'category': 'UNREAD',
        'title': 'BTC/USD SHORT SIGNAL TARGET HIT',
        'content': 'Short setup at \$68,200 hit target 1 (\$67,500) yielding +1.02% net gain.',
        'time': '4 hours ago',
        'type': 'signal',
        'isRead': 'false',
      },
      {
        'category': 'READ',
        'title': 'API CONNECTION ROTATED',
        'content': 'Websocket credentials successfully refreshed. System state synchronized with servers.',
        'time': '1 day ago',
        'type': 'system',
        'isRead': 'true',
      },
    ];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _verifyTxnCtrl.dispose();
    _verifyAmountCtrl.dispose();
    _utrCtrl.dispose();
    _amountPaidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening file explorer for audit screenshot...'),
        duration: Duration(seconds: 1),
      ),
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

  void _gainMockXP() {
    setState(() {
      _xpProgress += 250;
      if (_xpProgress >= _maxXp) {
        _xpProgress -= _maxXp;
        _userLevel += 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: buyGreen,
            content: Text(
              'LEVEL UP! You reached Level $_userLevel Specialist Rank!',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('+250 XP Gained from Terminal Engagement!'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _handleChangePassword() {
    final current = _currentPasswordCtrl.text;
    final valNew = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || valNew.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields.')),
      );
      return;
    }

    if (valNew != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    // Mock network request
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isChangingPassword = false);
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF0E0E0E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: gold, width: 1),
          ),
          title: const Text('Password Updated', style: TextStyle(color: gold)),
          content: const Text(
            'Your security credentials have been updated successfully.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: gold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Global Announcement Listener
    ref.listen(communityMessagesProvider, (previous, next) {
      if (next.hasValue && previous != null && previous.hasValue) {
        final nextMsgs = next.value!;
        final prevMsgs = previous.value!;
        if (nextMsgs.isNotEmpty && (prevMsgs.isEmpty || nextMsgs.first.id != prevMsgs.first.id)) {
          _showNewMessagePopup(nextMsgs.first);
        }
      }
    });

    final subAsync = ref.watch(userSubscriptionProvider);
    final String activePlan = subAsync.maybeWhen(
      data: (sub) => sub.planName.toUpperCase(),
      orElse: () => 'FREE',
    );

    final statusAsync = ref.watch(verificationStatusProvider);
    final String activeVerifyStatus = statusAsync.maybeWhen(
      data: (status) => status?.toUpperCase() ?? '',
      orElse: () => '',
    );

    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.black.withOpacity(0.55),
      drawer: _TerminalNavigationDrawer(
        activeMenu: _selectedMenu,
        activePlan: activePlan,
        activeVerifyStatus: activeVerifyStatus,
        unreadCount: 3,
        username: _nameCtrl.text,
        userLevel: _userLevel,
        currentXp: _xpProgress,
        maxXp: _maxXp,
        onSelect: (menu) {
          setState(() {
            _selectedMenu = menu;
          });
        },
      ),
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;

          return Row(
            children: [
              if (isWide) ...[
                _buildAccountNavigationSidebar(),
                const VerticalDivider(width: 1, thickness: 1, color: border),
              ],
              Expanded(
                child: Column(
                  children: [
                    if (!isWide) _buildAccountNavigationHorizontal(),
                    Expanded(
                      child: _buildMainScrollableContent(isWide),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainScrollableContent(bool isWide) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: isWide
          ? const EdgeInsets.all(24)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: [
        if (_selectedMenu == 'PROFILE') ...[
          _buildProfileSettingsHeader(),
          const SizedBox(height: 16),
          _buildPersonalInformationCard(),
          const SizedBox(height: 16),
          _buildNotificationPreferencesCard(),
          const SizedBox(height: 16),
          _buildProfileBillingCard(),
          const SizedBox(height: 16),
          _buildProfilePreferencesCard(),
          const SizedBox(height: 16),
          _buildProfileLegalCard(),
          const SizedBox(height: 16),
          _buildProfileDangerZoneCard(),
        ] else if (_selectedMenu == 'ALERTS') ...[
          _buildNotifications(),
        ] else if (_selectedMenu == 'PLAN') ...[
          _buildPlan(isWide),
        ] else if (_selectedMenu == 'HISTORY') ...[
          _buildBillingHeader(),
          const SizedBox(height: 16),
          _buildBilling(),
        ] else if (_selectedMenu == 'VERIFY') ...[
          _buildVerify(),
        ] else if (_selectedMenu == 'COMMUNITY') ...[
          _buildCommunityHeader(),
          const SizedBox(height: 16),
          _buildCommunityTabs(),
          const SizedBox(height: 16),
          _buildCommunityContent(),
        ] else if (_selectedMenu == 'HELP') ...[
          _buildSupport(),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionTitleHeader({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: const BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: monoStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textStyle(fontSize: 11, color: themeTextDim(context)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSettingsHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: gold.withOpacity(0.3), width: 0.5),
          ),
          child: const Icon(Icons.person_outline, color: gold, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROFILE & SETTINGS',
              style: monoStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage your account preferences',
              style: textStyle(fontSize: 10, color: themeTextDim(context)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInformationCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: gold, size: 14),
              const SizedBox(width: 8),
              Text('PERSONAL INFORMATION', style: labelCaps(color: gold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 12),
          _inputField('FULL NAME', _nameCtrl, null),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EMAIL ADDRESS', style: monoStyle(fontSize: 9, color: themeTextDim(context), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: bgDeep,
                  border: Border.all(color: borderFaint, width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        readOnly: true,
                        style: textStyle(fontSize: 11, color: Colors.white70),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.12),
                        border: Border.all(color: gold.withOpacity(0.3), width: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        'FREE',
                        style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputField('PHONE NUMBER', _phoneCtrl, null),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Changes saved successfully.')),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: gold,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text('SAVE CHANGES', style: monoStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none, color: gold, size: 14),
              const SizedBox(width: 8),
              Text('NOTIFICATION PREFERENCES', style: labelCaps(color: gold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 8),
          _toggleNotifRow('Broadcast Announcements', 'Stay updated with official news and updates', _notifBroadcast, (v) => setState(() => _notifBroadcast = v)),
          const Divider(color: borderFaint, height: 8),
          _toggleNotifRow('Support Replies', 'Get notified when support staff replies to your tickets', _notifSupport, (v) => setState(() => _notifSupport = v)),
          const Divider(color: borderFaint, height: 8),
          _toggleNotifRow('Signal Alerts', 'Receive real-time trading signals and alerts', _notifSignal, (v) => setState(() => _notifSignal = v)),
          const Divider(color: borderFaint, height: 8),
          _toggleNotifRow('Payment Updates', 'Notifications about your subscriptions and payments', _notifPayment, (v) => setState(() => _notifPayment = v)),
          const Divider(color: borderFaint, height: 8),
          _toggleNotifRow('In-App Push Notifications', 'Receive real-time alerts inside the app', _notifPush, (v) => setState(() => _notifPush = v)),
        ],
      ),
    );
  }

  Widget _toggleNotifRow(String title, String subtitle, bool val, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: textStyle(fontSize: 9, color: Colors.white38)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: val,
              activeColor: gold,
              activeTrackColor: gold.withOpacity(0.5),
              inactiveThumbColor: Colors.white30,
              inactiveTrackColor: borderFaint,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBillingCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: gold, size: 14),
              const SizedBox(width: 8),
              Text('BILLING', style: labelCaps(color: gold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _billingDisplayItem('CURRENCY', 'USD')),
                        const SizedBox(width: 12),
                        Expanded(child: _billingDisplayItem('CURRENT PLAN', 'Free')),
                        const SizedBox(width: 12),
                        Expanded(child: _billingDisplayItem('NEXT BILLING', '—')),
                      ],
                    )
                  : Column(
                      children: [
                        _billingDisplayItem('CURRENCY', 'USD'),
                        const SizedBox(height: 8),
                        _billingDisplayItem('CURRENT PLAN', 'Free'),
                        const SizedBox(height: 8),
                        _billingDisplayItem('NEXT BILLING', '—'),
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedMenu = 'HISTORY';
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: borderFaint, width: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Text('View Billing History', style: monoStyle(fontSize: 9, color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingDisplayItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: monoStyle(fontSize: 8, color: Colors.white30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgDeep,
            border: Border.all(color: borderFaint, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
             value,
             style: monoStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePreferencesCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language, color: gold, size: 14),
              const SizedBox(width: 8),
              Text('PREFERENCES', style: labelCaps(color: gold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _preferencesDropdownItem('Language', _prefLanguage, ['English', 'Spanish', 'German', 'French'], (v) => setState(() => _prefLanguage = v!))),
                        const SizedBox(width: 12),
                        Expanded(child: _preferencesDropdownItem('Time Zone', _prefTimeZone, ['UTC-5 (EST)', 'UTC+0 (GMT)', 'UTC+5:30 (IST)', 'UTC+8 (SGT)'], (v) => setState(() => _prefTimeZone = v!))),
                        const SizedBox(width: 12),
                        Expanded(child: _preferencesDropdownItem('Theme Mode', _prefTheme, ['Dark', 'Light', 'System'], (v) => setState(() => _prefTheme = v!))),
                      ],
                    )
                  : Column(
                      children: [
                        _preferencesDropdownItem('Language', _prefLanguage, ['English', 'Spanish', 'German', 'French'], (v) => setState(() => _prefLanguage = v!)),
                        const SizedBox(height: 8),
                        _preferencesDropdownItem('Time Zone', _prefTimeZone, ['UTC-5 (EST)', 'UTC+0 (GMT)', 'UTC+5:30 (IST)', 'UTC+8 (SGT)'], (v) => setState(() => _prefTimeZone = v!)),
                        const SizedBox(height: 8),
                        _preferencesDropdownItem('Theme Mode', _prefTheme, ['Dark', 'Light', 'System'], (v) => setState(() => _prefTheme = v!)),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _preferencesDropdownItem(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bgDeep,
            border: Border.all(color: borderFaint, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: bgDeep,
              isExpanded: true,
              style: monoStyle(fontSize: 10, color: Colors.white),
              icon: const Icon(Icons.keyboard_arrow_down, color: gold, size: 14),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileLegalCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: gold, size: 14),
              const SizedBox(width: 8),
              Text('LEGAL', style: labelCaps(color: gold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: borderFaint, height: 1),
          const SizedBox(height: 6),
          _legalTileItem('Terms & Conditions'),
          const Divider(color: borderFaint, height: 1),
          _legalTileItem('Privacy Policy'),
          const Divider(color: borderFaint, height: 1),
          _legalTileItem('Refund Policy'),
        ],
      ),
    );
  }

  Widget _legalTileItem(String title) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $title...')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: textStyle(fontSize: 11, color: Colors.white70)),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDangerZoneCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF140809),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: criticalRed.withOpacity(0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger Zone', style: monoStyle(fontSize: 10, color: criticalRed, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
             'Warning: Deleting your account is permanent and cannot be undone.',
             style: textStyle(fontSize: 9, color: Colors.white38),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _dangerButton('Logout', () async => await SupabaseAuthService.signOut(), isTransparent: true),
              const SizedBox(width: 10),
              _dangerButton('Cancel Subscription', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription cancellation requested.')),
                );
              }, isTransparent: true),
              const SizedBox(width: 10),
              _dangerButton('Delete Account', () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: bgDeep,
                    title: Text('Delete Account', style: monoStyle(color: criticalRed)),
                    content: Text('Are you sure you want to permanently delete your account?', style: textStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: monoStyle(color: Colors.white))),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await SupabaseAuthService.signOut();
                        },
                        child: Text('DELETE', style: monoStyle(color: criticalRed)),
                      ),
                    ],
                  ),
                );
              }, isTransparent: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onTap, {required bool isTransparent}) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isTransparent ? Colors.transparent : criticalRed,
          side: BorderSide(color: criticalRed, width: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: monoStyle(fontSize: 8, color: isTransparent ? criticalRed : Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAccountNavigationSidebar() {
    return Container(
      width: 240,
      color: themeSection(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'D TRADE TERMINAL',
                  style: monoStyle(fontSize: 12, fontWeight: FontWeight.bold, color: gold, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const Divider(color: borderFaint, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _sidebarCategoryHeader('NETWORK'),
                _sidebarNavItem(Icons.people_outline, 'COMMUNITY', 'COMMUNITY', 'Announcements & Forums'),
                
                _sidebarCategoryHeader('BILLING'),
                _sidebarNavItem(Icons.shield_outlined, 'PLAN', 'SUBSCRIPTION', 'Manage Your Plan'),
                _sidebarNavItem(Icons.receipt_long, 'HISTORY', 'PAYMENT HISTORY', 'Invoices & Records'),
                _sidebarNavItem(Icons.credit_card, 'VERIFY', 'VERIFY PAYMENT', 'Submit Crypto TXD'),
                
                _sidebarCategoryHeader('PREFERENCES'),
                _sidebarNavItem(Icons.settings_outlined, 'PROFILE', 'PROFILE SETTINGS', 'Security & Details'),
                _sidebarNavItem(Icons.notifications_none, 'ALERTS', 'NOTIFICATIONS', 'Alert Preferences'),
                _sidebarNavItem(Icons.help_outline, 'HELP', 'SUPPORT', 'Help Tickets'),
              ],
            ),
          ),
          const Divider(color: borderFaint, height: 1),
          _sidebarLogoutItem(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sidebarCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: monoStyle(fontSize: 9, color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  Widget _sidebarNavItem(IconData icon, String moduleId, String title, String subtitle) {
    final bool isSelected = _selectedMenu == moduleId;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMenu = moduleId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.05) : Colors.transparent,
          border: Border(left: BorderSide(color: isSelected ? gold : Colors.transparent, width: 2)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? gold : Colors.white60,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: monoStyle(
                      fontSize: 10,
                      color: isSelected ? gold : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: textStyle(
                      fontSize: 8,
                      color: isSelected ? gold.withOpacity(0.6) : Colors.white38,
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

  Widget _sidebarLogoutItem() {
    return InkWell(
      onTap: () async {
        await SupabaseAuthService.signOut();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.logout, color: sellRed, size: 16),
            const SizedBox(width: 12),
            Text(
              'LOGOUT',
              style: monoStyle(fontSize: 10, color: sellRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountNavigationHorizontal() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgElevated,
        border: Border(bottom: BorderSide(color: borderFaint, width: 0.5)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: bgDeep,
                    border: Border.all(color: borderFaint, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu, color: gold, size: 14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _selectedMenu,
            style: monoStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const Spacer(),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.logout, color: sellRed, size: 14),
              onPressed: () async => await SupabaseAuthService.signOut(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }



  Widget _buildCommunityHeader() {
    return _buildSectionTitleHeader(
      title: 'COMMUNITY NETWORK',
      subtitle: 'Official channels, announcements, and developer forums',
    );
  }

  Widget _buildCommunityTabs() {
    return Container(
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _communityTabItem('Announcements', Icons.campaign),
          _communityTabItem('Live Chat', Icons.chat_bubble_outline),
          _communityTabItem('Developer Forum', Icons.code),
        ],
      ),
    );
  }

  Widget _communityTabItem(String label, IconData icon) {
    final bool isActive = _communityTab == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _communityTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? gold.withOpacity(0.08) : Colors.transparent,
            border: Border(bottom: BorderSide(color: isActive ? gold : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isActive ? gold : themeTextDim(context), size: 16),
              const SizedBox(width: 8),
              Text(label, style: monoStyle(fontSize: 10, color: isActive ? gold : themeTextDim(context), fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityContent() {
    if (_communityTab == 'Announcements') {
      return _buildAnnouncementsView();
    } else {
      return _comingSoonCard(
        title: _communityTab,
        icon: _communityTab == 'Live Chat' ? Icons.chat_bubble_outline : Icons.code,
        subtitle: 'Live Socket integration for community engagement is coming soon in the next major build release.',
      );
    }
  }

  Widget _buildAnnouncementsView() {
    final messagesAsync = ref.watch(communityMessagesProvider);

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _buildMessageCard(CommunityMessage(
            id: 'welcome',
            title: 'Welcome to D Trade Terminal',
            content: "You have successfully completed early access setup of D Trade's proprietary behavioral terminal.\n\nOur system analyzes execution loops, latency, and trader fitness metrics. Explore the features and setup plan configs.",
            type: 'ANNOUNCEMENT',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ));
        }
        return Column(
          children: messages.map((m) => _buildMessageCard(m)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Failed to load announcements: $e', style: monoStyle(color: sellRed))),
    );
  }

  Widget _buildMessageCard(CommunityMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: gold.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(message.type.toUpperCase(), style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
              ),
              Text(
                DateFormat('MM/dd/yyyy hh:mm a').format(message.createdAt),
                style: monoStyle(fontSize: 9, color: themeTextDim(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message.title, style: textStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message.content, style: textStyle(fontSize: 12, color: Colors.white70, height: 1.5)),
          const SizedBox(height: 16),
          Text('— DTrade Compliance Team', style: monoStyle(fontSize: 9, color: themeTextDim(context))),
        ],
      ),
    );
  }

  Widget _comingSoonCard({required String title, required IconData icon, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold.withOpacity(0.5), size: 40),
          const SizedBox(height: 16),
          Text(title.toUpperCase(), style: monoStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: textStyle(fontSize: 12, color: themeTextDim(context))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: gold),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('COMING SOON', style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.3), width: 0.5),
              ),
              child: const Icon(Icons.notifications_none, color: gold, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ALERTS',
                    style: monoStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Notification feed & system announcements',
                    style: textStyle(fontSize: 10, color: themeTextDim(context)),
                  ),
                ],
              ),
            ),
            if (_allAlerts != null && _allAlerts!.isNotEmpty) ...[
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _allAlerts = [];
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sellRed.withOpacity(0.08),
                    border: Border.all(color: sellRed.withOpacity(0.3), width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: sellRed, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'CLEAR',
                        style: monoStyle(fontSize: 9, color: sellRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildInboxTabs(),
        const SizedBox(height: 16),
        _buildInboxContent(),
      ],
    );
  }

  Widget _buildInboxTabs() {
    final tabs = ['ALL', 'READ', 'UNREAD', 'SYSTEM', 'AUDIT'];
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderFaint, width: 0.5)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: tabs.map((t) {
          final isSelected = (_inboxTab == t) || (_inboxTab == 'ALL (0)' && t == 'ALL');
          return InkWell(
            onTap: () => setState(() => _inboxTab = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? gold : Colors.transparent,
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                t,
                style: monoStyle(
                  fontSize: 10,
                  color: isSelected ? gold : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInboxContent() {
    final allAlerts = _allAlerts ?? [];

    final filtered = allAlerts.where((a) {
      if (_inboxTab == 'ALL' || _inboxTab == 'ALL (0)') return true;
      if (_inboxTab == 'READ') return a['isRead'] == 'true';
      if (_inboxTab == 'UNREAD') return a['isRead'] == 'false';
      return a['category'] == _inboxTab;
    }).toList();

    if (filtered.isEmpty) {
      return _buildInboxEmptyState();
    }

    return Column(
      children: filtered.map((a) {
        IconData icon;
        Color color;
        if (a['type'] == 'audit') {
          icon = Icons.verified_user_outlined;
          color = buyGreen;
        } else if (a['type'] == 'billing') {
          icon = Icons.credit_card;
          color = gold;
        } else if (a['type'] == 'signal') {
          icon = Icons.trending_up;
          color = buyGreen;
        } else {
          icon = Icons.info_outline;
          color = Colors.white54;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgDeep,
            border: Border.all(color: borderFaint, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          a['title']!,
                          style: monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        Text(
                          a['time']!,
                          style: textStyle(fontSize: 8, color: Colors.white30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['content']!,
                      style: textStyle(fontSize: 9, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInboxEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.notifications_none, color: themeTextDim(context).withOpacity(0.3), size: 32),
            const SizedBox(height: 12),
            Text('NO NOTIFICATIONS FOUND', style: monoStyle(fontSize: 11, color: themeTextDim(context), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Notifications in this category will compile here.', style: textStyle(fontSize: 9, color: themeTextDim(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingHeader() {
    return _buildSectionTitleHeader(
      title: 'BILLING & PLAN RECORDS',
      subtitle: 'Manage active subscriptions, invoices, and crypto audits',
    );
  }

  Widget _buildBilling() {
    return Column(
      children: [
        _planStatsCard(),
        const SizedBox(height: 24),
        _paymentHistoryCard(),
      ],
    );
  }

  Widget _planStatsCard() {
    final subAsync = ref.watch(userSubscriptionProvider);

    return subAsync.when(
      data: (sub) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeSection(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ACTIVE ACCOUNT SUBSCRIPTION', style: monoStyle(fontSize: 10, color: themeTextDim(context), fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: gold.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text('${sub.planName} PLAN', style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(sub.planName, style: monoStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('STATUS: ${sub.status} • EXPIRY: ${sub.expiryDate ?? 'N/A'}', style: monoStyle(fontSize: 10, color: themeTextDim(context))),
            const Divider(color: border, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AUDIT ID: ${sub.auditId}', style: monoStyle(fontSize: 11)),
                TextButton(
                  onPressed: () => setState(() => _selectedMenu = 'VERIFY'),
                  style: TextButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('VERIFY TRANSACTION', style: monoStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Failed to load billing: $e', style: monoStyle(color: sellRed))),
    );
  }

  Widget _paymentHistoryCard() {
    final historyAsync = ref.watch(paymentHistoryProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRANSACTION LOGS & HISTORY', style: monoStyle(fontSize: 10, color: themeTextDim(context), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('NO PREVIOUS TRANSACTION RECORDS FOUND', style: monoStyle(fontSize: 9, color: themeTextDim(context)))),
                );
              }
              return Column(
                children: records.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.plan, style: textStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text('${r.date} • ${r.method}', style: monoStyle(fontSize: 9, color: themeTextDim(context))),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${r.amount}', style: monoStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(r.status, style: monoStyle(fontSize: 8, color: r.status == 'COMPLETED' ? buyGreen : gold)),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: gold)),
            error: (e, s) => Center(child: Text('System offline', style: monoStyle(color: sellRed))),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(bool isWide) {
    final subAsync = ref.watch(userSubscriptionProvider);
    return subAsync.when(
      data: (sub) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitleHeader(title: 'MY SUBSCRIPTION', subtitle: 'Manage your plan and billing'),
            const SizedBox(height: 20),
            
            // Active Subscription Info Row
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: themeSection(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.12),
                                border: Border.all(color: gold, width: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${sub.planName.toUpperCase()} PLAN',
                                style: monoStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: buyGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sub.status.toUpperCase(),
                                style: monoStyle(fontSize: 8, color: buyGreen, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.planName.toUpperCase(),
                          style: monoStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EXPIRY: ${sub.expiryDate ?? 'CONTACT ADMIN'}',
                          style: monoStyle(fontSize: 9, color: themeTextDim(context)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '24/7 SUPPORT',
                        style: monoStyle(fontSize: 9, color: gold, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: buyGreen, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              'PLAN ACTIVE',
                              style: monoStyle(fontSize: 9, color: buyGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            _buildSectionTitleHeader(title: 'SELECT ACCESS LEVEL', subtitle: 'Choose the plan that suits your trading scale'),
            const SizedBox(height: 16),
            
            // Plan Shortcut Buttons
            Row(
              children: [
                _buildPlanShortcutBtn('ZERO', _freeCardKey),
                const SizedBox(width: 10),
                _buildPlanShortcutBtn('CORE', _coreCardKey),
                const SizedBox(width: 10),
                _buildPlanShortcutBtn('GUARDIAN', _guardianCardKey),
              ],
            ),
            const SizedBox(height: 20),
            
            // Cards Layout
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSinglePlanCard('Free')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSinglePlanCard('Core')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSinglePlanCard('Guardian')),
                    ],
                  )
                : Column(
                    children: [
                      _buildSinglePlanCard('Free'),
                      const SizedBox(height: 16),
                      _buildSinglePlanCard('Core'),
                      const SizedBox(height: 16),
                      _buildSinglePlanCard('Guardian'),
                    ],
                  ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Failed to load billing: $e', style: monoStyle(color: sellRed))),
    );
  }

  Widget _buildSinglePlanCard(String planType) {
    final title = planType == 'Free' ? 'ZERO' : (planType == 'Core' ? 'CORE' : 'GUARDIAN');
    final subtitle = planType == 'Free' 
        ? 'Get started with AI-powered insights. Perfect for: Curious traders who want to test the platform.'
        : (planType == 'Core' 
            ? 'AI-powered self-awareness for your trading. Perfect for: Growing traders looking to audit their habits.' 
            : 'Real-time AI protection for your capital. Perfect for: Scale traders who need strict risk controls.');
    final price = planType == 'Free' ? 'Free' : (planType == 'Core' ? '\$9 / mo' : '\$29 / mo');
    final billingDesc = planType == 'Free' ? 'Lifetime access' : (planType == 'Core' ? 'Billed \$108 annually' : 'Billed \$348 annually');
    final saveBadge = planType == 'Free' ? null : (planType == 'Core' ? 'SAVE 60% OFF' : 'SAVE 66% OFF');
    final features = planType == 'Free' 
        ? [
            '3 AI-powered signals per week',
            'Community access (Telegram/Discord)',
            'Basic market analysis (weekly recap)',
            'Trading psychology mini-course (5 lessons)',
            'Risk calculator tool'
          ]
        : (planType == 'Core' 
            ? [
                'Trader Genome™ — Full Profile unlocked',
                'Weekly behavioral report (risk trends, discipline)',
                'EVI history & session tracking',
                'Emotional patterns (revenge loops, FOMO, size drift)',
                'Behavioral Fitness Score — weekly progress',
                'Email support'
              ]
            : [
                'Everything in Core',
                'Real-time behavioral intervention (hard blocks)',
                'Destruction sequence prediction',
                'Emotional Volatility Index — live dashboard',
                'Revenge trade auto-detection & block',
                'Position size cap enforcement',
                'Loss streak auto-shutdown',
                'Full AI Guardian — Behavioral Shield active',
                'Performance analytics dashboard',
                'Priority support (12hr response)'
              ]);

    final isSelected = _selectedPlan == planType;
    final cardKey = planType == 'Free' ? _freeCardKey : (planType == 'Core' ? _coreCardKey : _guardianCardKey);

    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? gold : border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: gold.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                planType == 'Free' 
                    ? Icons.shield_outlined 
                    : (planType == 'Core' ? Icons.flash_on : Icons.workspace_premium),
                color: planType == 'Free' ? Colors.white60 : gold,
                size: 20,
              ),
              if (saveBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: buyGreen.withOpacity(0.12),
                    border: Border.all(color: buyGreen, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    saveBadge,
                    style: monoStyle(fontSize: 8, color: buyGreen, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: monoStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textStyle(fontSize: 10, color: themeTextDim(context)),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: monoStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 4),
              if (planType != 'Free')
                Text(
                  '/ MONTH',
                  style: monoStyle(fontSize: 8, color: themeTextDim(context)),
                ),
            ],
          ),
          Text(
            billingDesc,
            style: monoStyle(fontSize: 9, color: themeTextDim(context)),
          ),
          if (planType == 'Guardian') ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'MOST POPULAR',
                style: monoStyle(fontSize: 7, color: gold, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Divider(color: border, height: 24),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, color: gold, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: textStyle(fontSize: 9.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedPlan = planType;
                });
                if (planType != 'Free') {
                  _showPaymentFlow(title, planType == 'Core' ? '\$9/mo' : '\$29/mo', planType == 'Core' ? '108' : '348');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are already on the ZERO (Free) Plan.')),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'SELECT $title',
                style: monoStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanShortcutBtn(String label, GlobalKey cardKey) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Scrollable.ensureVisible(
            cardKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: monoStyle(
              fontSize: 10,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentFlow(String planName, String priceText, String rawPrice) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return _PaymentFlowDialog(
          planName: planName,
          priceText: priceText,
          rawPrice: rawPrice,
          onComplete: (method, amount, utr) async {
            final success = await ref.read(billingServiceProvider).submitVerification(
              method: method,
              amount: amount,
              utr: utr,
              date: DateTime.now().toIso8601String().split('T')[0],
              notes: 'Audit request for subscription upgrade to $planName.',
              planType: planName.toUpperCase(),
            );
            if (success) {
              ref.refresh(userSubscriptionProvider);
              ref.refresh(verificationStatusProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: buyGreen,
                  content: Text('Payment verification request for $planName submitted!'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: sellRed,
                  content: Text('Failed to submit verification request. Please try again.'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildVerify() {
    final statusAsync = ref.watch(verificationStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == 'UNDER REVIEW' || status?.toUpperCase() == 'PENDING') {
          return _statusPanel('UNDER REVIEW', 'Our auditors are checking your UTR. Verification completes in 1-2 hours.', Icons.hourglass_empty, gold);
        } else if (status == 'COMPLETED' || status?.toUpperCase() == 'APPROVED') {
          return _statusPanel('VERIFIED', 'Verification success! Limits updated.', Icons.check_circle_outline, buyGreen);
        }
        return _buildVerifyForm();
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => _buildVerifyForm(),
    );
  }

  Widget _statusPanel(String title, String subtitle, IconData icon, Color color) {
    final isUnderReview = title.toUpperCase().contains('REVIEW') || title.toUpperCase().contains('PENDING');
    
    return Center(
      child: Container(
        maxWidth: 600,
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0A07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle background glow using RadialGradient
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.08),
                        color.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing Status Icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            border: Border.all(
                              color: color.withOpacity(0.1 + (_pulseController.value * 0.3)),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(_pulseController.value * 0.15),
                                blurRadius: 15 + (_pulseController.value * 15),
                                spreadRadius: _pulseController.value * 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      title.toUpperCase(),
                      style: monoStyle(
                        fontSize: 20,
                        color: color,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: textStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Stepper / Timeline
                    const Divider(color: Color(0xFF1E1C1A), height: 1),
                    const SizedBox(height: 24),
                    _buildStatusTimeline(isUnderReview),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF1E1C1A), height: 1),
                    const SizedBox(height: 24),

                    // Audit info block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13100D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E1C1A), width: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSACTION AUDIT CODE',
                                style: monoStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'DTC-TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                                style: monoStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withOpacity(0.2), width: 0.5),
                            ),
                            child: Text(
                              isUnderReview ? 'PROCESSING' : 'VERIFIED',
                              style: monoStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _selectedMenu = 'PROFILE'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(color: Color(0xFF333333)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'BACK TO PROFILE',
                              style: monoStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _selectedMenu = 'HELP'),
                            style: TextButton.styleFrom(
                              backgroundColor: gold,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'GET HELP / SUPPORT',
                              style: monoStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStatusTimeline(bool isUnderReview) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timelineStep('Submitted', 'Proof uploaded', true, false),
        _timelineConnector(true),
        _timelineStep('Auditing', 'Matching UTR', isUnderReview, isUnderReview),
        _timelineConnector(!isUnderReview),
        _timelineStep('Upgraded', 'Access unlocked', !isUnderReview, false),
      ],
    );
  }

  Widget _timelineConnector(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? gold.withOpacity(0.5) : const Color(0xFF222222),
      ),
    );
  }

  Widget _timelineStep(String label, String sub, bool isVisited, bool isCurrent) {
    Color stepColor = isCurrent 
        ? gold 
        : (isVisited ? buyGreen : Colors.white24);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: stepColor,
              width: 1.5,
            ),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: gold.withOpacity(0.2),
                blurRadius: 8,
              )
            ] : null,
          ),
          child: Center(
            child: isCurrent
                ? const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(gold),
                    ),
                  )
                : (isVisited
                    ? const Icon(Icons.check, size: 12, color: buyGreen)
                    : const Icon(Icons.lock_outline, size: 10, color: Colors.white24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: monoStyle(
            fontSize: 10,
            color: isVisited || isCurrent ? Colors.white : Colors.white30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: textStyle(
            fontSize: 8,
            color: isVisited || isCurrent ? Colors.white54 : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeSection(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRANSACTION AUDIT FORM', style: monoStyle(fontSize: 12, color: gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _paymentMethodDropdown(),
          const SizedBox(height: 12),
          _inputField('UTR / TXID REFERENCE', _utrCtrl, null),
          const SizedBox(height: 12),
          _inputField('EXACT AMOUNT PAID (\$)', _amountPaidCtrl, null),
          const SizedBox(height: 12),
          _notesArea(),
          const SizedBox(height: 16),
          _uploadScreenshotWidget(),
          const SizedBox(height: 24),
          _isUploading
              ? const Center(child: CircularProgressIndicator(color: gold))
              : SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _submitVerificationAudit,
                    style: TextButton.styleFrom(backgroundColor: gold, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text('SUBMIT AUDIT REPORT', style: monoStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _paymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT SOURCE METHOD', style: monoStyle(fontSize: 9, color: themeTextDim(context), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.black, border: Border.all(color: border), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPaymentMethod,
              dropdownColor: themeSection(context),
              isExpanded: true,
              style: textStyle(fontSize: 12),
              items: ['Bank Transfer', 'Crypto (USDT)', 'Stripe', 'PayPal']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadScreenshotWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UPLOAD AUDIT SCREENSHOT', style: monoStyle(fontSize: 9, color: themeTextDim(context), fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _selectedImageBytes != null ? gold : border, style: BorderStyle.solid),
            ),
            child: Center(
              child: _selectedImageName != null
                  ? Text(_selectedImageName!, style: monoStyle(fontSize: 10, color: gold))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Colors.white30, size: 24),
                        const SizedBox(height: 4),
                        Text('SELECT SCREENSHOT FILE', style: monoStyle(fontSize: 9, color: themeTextDim(context))),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _submitVerificationAudit() async {
    final utr = _utrCtrl.text.trim();
    final amount = _amountPaidCtrl.text.trim();

    if (utr.isEmpty || amount.isEmpty || _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields (UTR, Amount, Screenshot) are mandatory.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final success = await ref.read(billingServiceProvider).submitVerification(
          method: _selectedPaymentMethod,
          amount: amount,
          utr: utr,
          date: DateFormat('yyyy-MM-dd').format(_selectedPaymentDate),
          notes: _notesCtrl.text,
          imageBytes: _selectedImageBytes,
          imageName: _selectedImageName,
          planType: _selectedPlan.toUpperCase(),
        );
    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit details submitted successfully.')),
      );
      _utrCtrl.clear();
      _amountPaidCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _selectedImageBytes = null;
        _selectedImageName = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit details. Check connection.')),
      );
    }
  }

  Widget _buildSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: gold.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.3), width: 0.5),
              ),
              child: const Icon(Icons.help_outline, color: gold, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HELP & SUPPORT',
                  style: monoStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submit support tickets and view history',
                  style: textStyle(fontSize: 10, color: themeTextDim(context)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSupportTabs(),
        const SizedBox(height: 16),
        _buildSupportTabContent(),
      ],
    );
  }

  Widget _buildSupportTabs() {
    final tabs = ['ACTIVE', 'SOLVED', 'CREATE TICKET'];
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderFaint, width: 0.5)),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _supportTab == t || (_supportTab == 'Active Tickets' && t == 'ACTIVE') || (_supportTab == 'Solved Tickets' && t == 'SOLVED');
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  if (t == 'ACTIVE') _supportTab = 'Active Tickets';
                  else if (t == 'SOLVED') _supportTab = 'Solved Tickets';
                  else _supportTab = 'CREATE TICKET';
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? gold : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Text(
                  t,
                  style: monoStyle(
                    fontSize: 10,
                    color: isSelected ? gold : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSupportTabContent() {
    if (_supportTab == 'CREATE TICKET') {
      return _buildSupportCreateTicketForm();
    }

    final ticketsAsync = ref.watch(userTicketsProvider);
    return ticketsAsync.when(
      data: (tickets) {
        final isActiveTab = _supportTab == 'Active Tickets';
        final filtered = tickets.where((t) {
          if (isActiveTab) return t.status == 'OPEN';
          return t.status == 'RESOLVED' || t.status == 'CLOSED';
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, color: themeTextDim(context).withOpacity(0.3), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    isActiveTab ? 'NO ACTIVE TICKETS' : 'NO SOLVED TICKETS',
                    style: monoStyle(fontSize: 11, color: themeTextDim(context), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActiveTab
                        ? 'All support requests have been resolved or closed.'
                        : 'No historical tickets found.',
                    style: textStyle(fontSize: 9, color: themeTextDim(context)),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: filtered.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgDeep,
              border: Border.all(color: borderFaint, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: (t.status == 'OPEN' ? gold : buyGreen).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long, color: t.status == 'OPEN' ? gold : buyGreen, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TICKET #${t.id.substring(0, 8).toUpperCase()}',
                            style: monoStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: t.status == 'OPEN' ? gold.withOpacity(0.5) : buyGreen.withOpacity(0.5),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              t.status,
                              style: monoStyle(
                                fontSize: 8,
                                color: t.status == 'OPEN' ? gold : buyGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.category} • ${t.subject}',
                        style: textStyle(fontSize: 9, color: Colors.white54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last update: ${DateFormat('MM/dd/yyyy HH:mm').format(t.createdAt)}',
                        style: monoStyle(fontSize: 8, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Support servers offline', style: monoStyle(color: sellRed))),
    );
  }

  Widget _buildSupportCreateTicketForm() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'BILLING';

    return StatefulBuilder(
      builder: (context, setFormState) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgDeep,
          border: Border.all(color: borderFaint, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CREATE HELP REQUEST TICKET', style: monoStyle(fontSize: 10, color: gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Divider(color: borderFaint, height: 1),
            const SizedBox(height: 12),
            Text('TICKET CATEGORY', style: monoStyle(fontSize: 9, color: themeTextDim(context), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: bgDeep,
                border: Border.all(color: borderFaint, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  dropdownColor: bgDeep,
                  isExpanded: true,
                  style: monoStyle(fontSize: 10, color: Colors.white),
                  icon: const Icon(Icons.keyboard_arrow_down, color: gold, size: 14),
                  items: ['BILLING', 'BUG REPORT', 'GENERAL INQUIRY', 'FEATURE REQUEST']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setFormState(() => category = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inputField('SUBJECT SUMMARY', subjectCtrl, null),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DETAILED DESCRIPTION', style: monoStyle(fontSize: 9, color: themeTextDim(context), fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgDeep,
                    border: Border.all(color: borderFaint, width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: textStyle(fontSize: 11, color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your issue description here...',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  if (subjectCtrl.text.isEmpty || descCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all support fields.')));
                    return;
                  }
                  final success = await ref.read(supportServiceProvider).createTicket(subjectCtrl.text.trim(), category, descCtrl.text.trim());
                  if (success) {
                    ref.invalidate(userTicketsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket created successfully!')));
                    setState(() {
                      _supportTab = 'Active Tickets';
                    });
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: gold,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text('SUBMIT TICKET', style: monoStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, Widget? extra, {bool readOnly = false, bool isObscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelCaps(color: textMid)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bgDeep,
            border: Border.all(color: borderFaint, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  readOnly: readOnly,
                  obscureText: isObscure,
                  style: textStyle(fontSize: 11, color: readOnly ? textLow : Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (extra != null) extra,
            ],
          ),
        ),
      ],
    );
  }

  Widget _notesArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADDITIONAL AUDIT NOTES', style: labelCaps(color: textMid)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgDeep,
            border: Border.all(color: borderFaint, width: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _notesCtrl,
            maxLines: 3,
            style: textStyle(fontSize: 11),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Any transaction notes or confirmations...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 10),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
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
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gold.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: gold,
                radius: 12,
                child: Icon(Icons.campaign, color: Colors.black, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEW ANNOUNCEMENT', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(message.title, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
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
}

class _TerminalNavigationDrawer extends StatelessWidget {
  final String activeMenu;
  final String activePlan;
  final String activeVerifyStatus;
  final int unreadCount;
  final String username;
  final int userLevel;
  final double currentXp;
  final double maxXp;
  final ValueChanged<String> onSelect;

  const _TerminalNavigationDrawer({
    required this.activeMenu,
    required this.activePlan,
    required this.activeVerifyStatus,
    required this.unreadCount,
    required this.username,
    required this.userLevel,
    required this.currentXp,
    required this.maxXp,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      width: min(MediaQuery.of(context).size.width * 0.82, 300.0),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFF222222), width: 1)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TERMINAL NAVIGATION',
                          style: textStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: gold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF2A2A2A)),
                            ),
                            child: const Icon(Icons.close, size: 13, color: Color(0xFF666666)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'D TRADE CAPITAL · SESSION ACTIVE',
                      style: textStyle(
                        fontSize: 10,
                        color: const Color(0xFF444444),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  username,
                  style: textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEEEEEE),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildSectionHeader('ACCOUNT'),
                    _buildNavItem(
                      context: context,
                      label: 'Account Settings',
                      hint: 'Profile · security · prefs',
                      moduleId: 'PROFILE',
                      icon: Icons.settings_outlined,
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Community Center',
                      hint: 'Forum · announcements',
                      moduleId: 'COMMUNITY',
                      icon: Icons.people_outline,
                      badgeText: '3 NEW',
                      badgeColor: const Color(0xFF00C853),
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Subscription Plans',
                      hint: '$activePlan plan · active',
                      moduleId: 'PLAN',
                      icon: Icons.shield_outlined,
                      badgeText: activePlan,
                      badgeColor: gold,
                    ),
                    _buildDivider(),
                    _buildSectionHeader('BILLING'),
                    _buildNavItem(
                      context: context,
                      label: 'Billing History',
                      hint: 'Invoices · records',
                      moduleId: 'HISTORY',
                      icon: Icons.receipt_long,
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Payment Audits',
                      hint: 'Submit · verify',
                      moduleId: 'VERIFY',
                      icon: Icons.credit_card,
                      badgeText: activeVerifyStatus == 'UNDER REVIEW' ? 'PENDING' : null,
                      badgeColor: const Color(0xFFFF1744),
                    ),
                    _buildDivider(),
                    _buildSectionHeader('SYSTEM'),
                    _buildNavItem(
                      context: context,
                      label: 'Notification Center',
                      hint: 'Alerts · preferences',
                      moduleId: 'ALERTS',
                      icon: Icons.notifications_none,
                      badgeText: unreadCount > 0 ? unreadCount.toString() : null,
                      badgeColor: gold,
                    ),
                    _buildNavItem(
                      context: context,
                      label: 'Help Desk',
                      hint: 'Support ticket logs',
                      moduleId: 'HELP',
                      icon: Icons.help_outline,
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CONNECTED · DEMO MODE',
                          style: textStyle(
                            fontSize: 10,
                            color: const Color(0xFF444444),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _confirmSignOut(context),
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Color(0xFFFF1744), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'SIGN OUT',
                            style: textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF1744),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 4),
      child: Text(
        title,
        style: textStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      height: 0.5,
      color: const Color(0xFF1E1E1E),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String label,
    required String hint,
    required String moduleId,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = activeMenu == moduleId;

    return GestureDetector(
      onTap: () {
        onSelect(moduleId);
        Navigator.pop(context);
      },
      child: Stack(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: isSelected ? const Color(0xFF141008) : Colors.transparent,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x1AF5A623) : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: isSelected ? gold : const Color(0xFF555555)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: textStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFFEEEEEE) : const Color(0xFF999999),
                        ),
                      ),
                      Text(
                        hint,
                        style: textStyle(
                          fontSize: 10,
                          color: const Color(0xFF444444),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? gold).withOpacity(0.12),
                      border: Border.all(color: badgeColor ?? gold, width: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      badgeText,
                      style: monoStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: badgeColor ?? gold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              left: 0,
              top: 4,
              bottom: 4,
              child: Container(
                width: 2,
                decoration: const BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF222222)),
        ),
        title: Text(
          'SIGN OUT',
          style: monoStyle(color: const Color(0xFFFF1744), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to end your terminal session?',
          style: textStyle(color: Colors.white70, fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: monoStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await SupabaseAuthService.signOut();
            },
            child: Text(
              'SIGN OUT',
              style: monoStyle(color: const Color(0xFFFF1744), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentFlowDialog extends StatefulWidget {
  final String planName;
  final String priceText;
  final String rawPrice;
  final Function(String method, String amount, String utr) onComplete;

  const _PaymentFlowDialog({
    required this.planName,
    required this.priceText,
    required this.rawPrice,
    required this.onComplete,
  });

  @override
  State<_PaymentFlowDialog> createState() => _PaymentFlowDialogState();
}

class _PaymentFlowDialogState extends State<_PaymentFlowDialog> {
  int _currentStep = 0; // 0: Choose, 1: UPI, 2: PayPal/Card, 3: Crypto
  String _selectedCrypto = 'USDT';
  
  // Controllers
  final _utrCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  
  final _cryptoSenderCtrl = TextEditingController();
  final _cryptoTxidCtrl = TextEditingController();

  // Timer for crypto
  Timer? _timer;
  int _secondsRemaining = 1799; // 29:59
  bool _isProcessing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _utrCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    _cryptoSenderCtrl.dispose();
    _cryptoTxidCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 1799;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTimer() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  // Styles helpers
  TextStyle _mStyle({required double fontSize, Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
      color: color ?? Colors.white,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  TextStyle _tStyle({required double fontSize, Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      color: color ?? Colors.white,
      fontWeight: fontWeight ?? FontWeight.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0C0C0C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF222222), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentStep == 0) _buildStepChooseMethod(),
            if (_currentStep == 1) _buildStepUPI(),
            if (_currentStep == 2) _buildStepPaypalCard(),
            if (_currentStep == 3) _buildStepCrypto(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepChooseMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CHOOSE PAYMENT METHOD',
              style: _mStyle(fontSize: 12, color: gold, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.planName} Plan — ${widget.priceText} (Billed Annually)',
          style: _tStyle(fontSize: 10, color: Colors.white54),
        ),
        const SizedBox(height: 20),
        
        // UPI Card
        _buildMethodSelector(
          title: 'UPI (INSTANT)',
          subtitle: 'GOOGLE PAY, PHONEPE, PAYTM',
          icon: Icons.qr_code_scanner,
          tintColor: buyGreen,
          bgColor: const Color(0xFF0A1B13),
          borderColor: const Color(0xFF1E3A2F),
          onTap: () {
            setState(() {
              _currentStep = 1;
            });
          },
        ),
        const SizedBox(height: 12),
        
        // PayPal / Cards Card
        _buildMethodSelector(
          title: 'PAYPAL / CARDS',
          subtitle: 'CREDIT/DEBIT CARD & PAYPAL',
          icon: Icons.credit_card,
          tintColor: const Color(0xFF4A90E2),
          bgColor: const Color(0xFF091426),
          borderColor: const Color(0xFF1B2E4C),
          onTap: () {
            setState(() {
              _currentStep = 2;
            });
          },
        ),
        const SizedBox(height: 12),
        
        // Crypto Card
        _buildMethodSelector(
          title: 'CRYPTOCURRENCY',
          subtitle: 'BTC, ETH, SOL, USDT & MORE',
          icon: Icons.currency_exchange,
          tintColor: const Color(0xFFBD10E0),
          bgColor: const Color(0xFF1A0A26),
          borderColor: const Color(0xFF381B4C),
          onTap: () {
            setState(() {
              _currentStep = 3;
            });
            _startTimer();
          },
        ),
        
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white38, size: 12),
            const SizedBox(width: 6),
            Text(
              'Secure & encrypted payment network',
              style: _mStyle(fontSize: 8, color: Colors.white38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodSelector({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color tintColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tintColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tintColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _mStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _mStyle(fontSize: 8, color: tintColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStepUPI() {
    final inrVal = widget.planName == 'CORE' ? '8,999' : '26,999';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
              onPressed: () => setState(() => _currentStep = 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              'UPI PAYMENT',
              style: _mStyle(fontSize: 12, color: buyGreen, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 16),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '₹$inrVal INR — ${widget.planName} (ANNUAL)',
          style: _mStyle(fontSize: 9, color: Colors.white38),
        ),
        const SizedBox(height: 16),
        
        // QR Code Display
        Center(
          child: Column(
            children: [
              _QrCodeWidget(),
              const SizedBox(height: 10),
              Text(
                'Scan to pay ₹$inrVal',
                style: _mStyle(fontSize: 9, color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Copy UPI ID
        Text(
          'OR PAY TO UPI ID:',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'sarathim1000@okhdfcbank',
                style: _mStyle(fontSize: 10, color: Colors.white70),
              ),
              InkWell(
                onTap: () => _copyToClipboard('sarathim1000@okhdfcbank', 'UPI ID'),
                child: Text(
                  'COPY ID',
                  style: _mStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Form field: UTR
        Text(
          'UPI TRANSACTION ID (UTR / REF NO.):',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _utrCtrl,
            style: _mStyle(fontSize: 11, color: Colors.white70),
            decoration: InputDecoration(
              hintText: 'Enter 12-digit transaction Ref Number',
              hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const SizedBox(height: 20),
        
        // Pay button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              final utr = _utrCtrl.text.trim();
              if (utr.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid Transaction Ref Number.')),
                );
                return;
              }
              Navigator.pop(context);
              widget.onComplete('UPI', widget.rawPrice, utr);
            },
            style: TextButton.styleFrom(
              backgroundColor: buyGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              '✓ I HAVE COMPLETED PAYMENT',
              style: _mStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepPaypalCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
              onPressed: () => setState(() => _currentStep = 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              'CREDIT CARD / PAYPAL',
              style: _mStyle(fontSize: 12, color: const Color(0xFF4A90E2), fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 16),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${widget.planName} Plan — ${widget.priceText} (Billed Annually)',
          style: _mStyle(fontSize: 9, color: Colors.white38),
        ),
        const SizedBox(height: 16),
        
        // Brand Icons Mock
        Row(
          children: [
            const Icon(Icons.credit_card, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              'WE ACCEPT ALL MAJOR CARDS & PAYPAL',
              style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        // Cardholder Name
        Text(
          'CARDHOLDER NAME',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _cardNameCtrl,
            style: _mStyle(fontSize: 10, color: Colors.white70),
            decoration: InputDecoration(
              hintText: 'John Doe',
              hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Card Number
        Text(
          'CARD NUMBER',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _cardNumberCtrl,
            style: _mStyle(fontSize: 10, color: Colors.white70),
            decoration: InputDecoration(
              hintText: '4111 2222 3333 4444',
              hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 10),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPIRY DATE (MM/YY)',
                    style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: const Color(0xFF222222)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _cardExpiryCtrl,
                      style: _mStyle(fontSize: 10, color: Colors.white70),
                      decoration: InputDecoration(
                        hintText: '12/28',
                        hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CVV',
                    style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: const Color(0xFF222222)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextField(
                      controller: _cardCvvCtrl,
                      style: _mStyle(fontSize: 10, color: Colors.white70),
                      decoration: InputDecoration(
                        hintText: '000',
                        hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: InputBorder.none,
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        if (_isProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                final name = _cardNameCtrl.text.trim();
                final num = _cardNumberCtrl.text.trim();
                final exp = _cardExpiryCtrl.text.trim();
                final cvv = _cardCvvCtrl.text.trim();
                
                if (name.isEmpty || num.isEmpty || exp.isEmpty || cvv.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all credit card details.')),
                  );
                  return;
                }
                
                setState(() {
                  _isProcessing = true;
                });
                
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                    Navigator.pop(context);
                    widget.onComplete('Stripe/Cards', widget.rawPrice, 'TXN-${Random().nextInt(999999) + 100000}');
                  }
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'PAY \$${widget.rawPrice} SECURELY',
                style: _mStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepCrypto() {
    // Generate mock values based on plan
    final isCore = widget.planName == 'CORE';
    final amountUsdt = isCore ? '108' : '348';
    
    String coinAmount = '';
    String depositAddr = '';
    String coinNetwork = '';
    
    if (_selectedCrypto == 'BTC') {
      coinAmount = isCore ? '0.0012' : '0.0039';
      depositAddr = '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy';
      coinNetwork = 'BITCOIN MAINNET';
    } else if (_selectedCrypto == 'ETH') {
      coinAmount = isCore ? '0.032' : '0.103';
      depositAddr = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      coinNetwork = 'ETHEREUM MAINNET (ERC-20)';
    } else if (_selectedCrypto == 'SOL') {
      coinAmount = isCore ? '0.65' : '2.09';
      depositAddr = 'HN7cABFi4ED52G5zLJsp89qYv48667E';
      coinNetwork = 'SOLANA SPL';
    } else if (_selectedCrypto == 'USDT') {
      coinAmount = amountUsdt;
      depositAddr = '0x71C7656EC7ab88b098defB751B7401B5f6d8976F';
      coinNetwork = 'USDT (ERC-20 / TRC-20)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
              onPressed: () => setState(() => _currentStep = 0),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              'CRYPTO PAYMENT',
              style: _mStyle(fontSize: 12, color: const Color(0xFFBD10E0), fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 16),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        
        // Blinking state row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const _BlinkingDot(),
                const SizedBox(width: 6),
                Text(
                  'AWAITING CONFIRMATIONS...',
                  style: _mStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              'TIMEOUT: ${_formatTimer()}',
              style: _mStyle(fontSize: 8, color: const Color(0xFFFF1744), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        // Coin Selector Tabs
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: ['USDT', 'BTC', 'ETH', 'SOL'].map((coin) {
              final isCoinSelected = _selectedCrypto == coin;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedCrypto = coin),
                  child: Container(
                    alignment: Alignment.center,
                    color: isCoinSelected ? const Color(0xFFBD10E0).withOpacity(0.12) : Colors.transparent,
                    child: Text(
                      coin,
                      style: _mStyle(
                        fontSize: 9,
                        color: isCoinSelected ? const Color(0xFFBD10E0) : Colors.white60,
                        fontWeight: isCoinSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        
        // Deposit Details Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F071A),
            border: Border.all(color: const Color(0xFF381B4C)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SEND AMOUNT', style: _mStyle(fontSize: 8, color: Colors.white38)),
                  Text('NETWORK: $coinNetwork', style: _mStyle(fontSize: 8, color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$coinAmount $_selectedCrypto',
                    style: _mStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  InkWell(
                    onTap: () => _copyToClipboard(coinAmount, 'Amount'),
                    child: Text('COPY AMOUNT', style: _mStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF381B4C), height: 16),
              Text('DEPOSIT ADDRESS', style: _mStyle(fontSize: 8, color: Colors.white38)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      depositAddr,
                      style: _mStyle(fontSize: 9, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(depositAddr, 'Wallet Address'),
                    child: Text('COPY ADDRESS', style: _mStyle(fontSize: 8, color: gold, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        
        // User fields
        Text(
          'YOUR SENDING ADDRESS (WALLET):',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _cryptoSenderCtrl,
            style: _mStyle(fontSize: 10, color: Colors.white70),
            decoration: InputDecoration(
              hintText: 'Enter your sending wallet address for proof',
              hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        Text(
          'TRANSACTION HASH (TXID):',
          style: _mStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            border: Border.all(color: const Color(0xFF222222)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: _cryptoTxidCtrl,
            style: _mStyle(fontSize: 10, color: Colors.white70),
            decoration: InputDecoration(
              hintText: 'Enter TXID Hash / TxRef',
              hintStyle: _mStyle(fontSize: 9, color: Colors.white24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              final sender = _cryptoSenderCtrl.text.trim();
              final txid = _cryptoTxidCtrl.text.trim();
              
              if (sender.isEmpty || txid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your sending address and Transaction Hash.')),
                );
                return;
              }
              
              Navigator.pop(context);
              widget.onComplete('Crypto ($_selectedCrypto)', amountUsdt, txid);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFBD10E0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              '✓ COMPLETED TRANSFER',
              style: _mStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: gold,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QrCodeWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(
        painter: _QrCodePainter(),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background matrix dots
    final random = Random(42);
    const dotSize = 4.0;
    const spacing = 8.0;
    
    // Draw QR Finder patterns (squares in corners)
    final finderPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-Left Finder
    canvas.drawRect(const Rect.fromLTWH(8, 8, 32, 32), finderPaint);
    canvas.drawRect(const Rect.fromLTWH(14, 14, 20, 20), Paint()..color = const Color(0xFF10B981));

    // Top-Right Finder
    canvas.drawRect(Rect.fromLTWH(size.width - 40, 8, 32, 32), finderPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - 34, 14, 20, 20), Paint()..color = const Color(0xFF10B981));

    // Bottom-Left Finder
    canvas.drawRect(Rect.fromLTWH(8, size.height - 40, 32, 32), finderPaint);
    canvas.drawRect(Rect.fromLTWH(14, size.height - 34, 20, 20), Paint()..color = const Color(0xFF10B981));

    // Draw random techy QR blocks
    final blockPaint = Paint()..color = const Color(0xFF000000);
    for (double x = 40; x < size.width - 40; x += spacing) {
      for (double y = 8; y < size.height - 8; y += spacing) {
        if (random.nextDouble() > 0.45) {
          canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, dotSize, dotSize), blockPaint);
        }
      }
    }
    
    // Draw some lines for tech feel
    for (double x = 8; x < size.width - 8; x += spacing) {
      // Bottom area
      for (double y = size.height - 40; y < size.height - 8; y += spacing) {
        if (x < 40) continue; // Skip Finder
        if (random.nextDouble() > 0.4) {
          canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, dotSize, dotSize), blockPaint);
        }
      }
      // Right area
      for (double y = 8; y < size.height - 40; y += spacing) {
        if (x >= size.width - 40) {
          if (y >= 40) {
            if (random.nextDouble() > 0.4) {
              canvas.drawRect(Rect.fromLTWH(x + 2, y + 2, dotSize, dotSize), blockPaint);
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

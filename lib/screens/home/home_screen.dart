import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/language_provider.dart';
import '../health_records/health_records_list_screen.dart';
import '../health_records/add_health_record_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../timeline/medical_timeline_screen.dart';
import '../family/family_dashboard_screen.dart';
import '../profile/health_calculator_screen.dart';
import '../../widgets/sidebar_drawer.dart';
import '../share/select_history_to_share_screen.dart';
import '../share/qr_code_scanner_screen.dart';

/// Home screen with bottom navigation and dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer data loading to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Load initial data
  Future<void> _loadData() async {
    if (!mounted) return;
    final healthRecordProvider = context.read<HealthRecordProvider>();
    final familyProvider = context.read<FamilyProvider>();
    await Future.wait([
      healthRecordProvider.loadHealthRecords(),
      familyProvider.loadFamilyMembers(),
    ]);
  }

  /// Handle navigation bar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: isMobile ? null : _buildTopNavigationBar(languageProvider),
      drawer: const SidebarDrawer(),
      body: _buildBody(isMobile),
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Get.to(() => const AddHealthRecordScreen());
              },
              icon: const Icon(Icons.add),
              label: Text(languageProvider.tr('add_record')),
            )
          : null,
    );
  }

  /// Build top navigation bar for web/desktop
  PreferredSizeWidget _buildTopNavigationBar(LanguageProvider languageProvider) {
    final navigationItems = [
      {'label': languageProvider.tr('home'), 'index': 0},
      {'label': languageProvider.tr('records'), 'index': 1},
      {'label': languageProvider.tr('medical_history'), 'index': 2},
      {'label': languageProvider.tr('family'), 'index': 3},
      {'label': languageProvider.tr('ai_assistant'), 'index': 4},
    ];

    return AppBar(
      title: Row(
        children: navigationItems.map((item) {
          return TextButton(
            onPressed: () => _onItemTapped(item['index'] as int),
            style: TextButton.styleFrom(
              foregroundColor: _selectedIndex == (item['index'] as int)
                  ? AppColors.textWhite
                  : AppColors.textWhite.withOpacity(0.7),
            ),
            child: Text(item['label'] as String),
          );
        }).toList(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle, color: AppColors.textWhite),
          onPressed: () {
            // TODO: Navigate to profile screen or show profile dropdown
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textWhite),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ],
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textWhite,
    );
  }

  /// Build the body content based on selected tab
  Widget _buildBody(bool isMobile) {
    switch (_selectedIndex) {
      case 0:
        return _DashboardTab(showAppBar: isMobile);
      case 1:
        return const HealthRecordsListScreen();
      case 2:
        return const MedicalTimelineScreen();
      case 3:
        return const FamilyDashboardScreen();
      case 4:
        return const AiChatScreen();
      default:
        return _DashboardTab(showAppBar: isMobile);
    }
  }

  /// Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    final languageProvider = context.watch<LanguageProvider>();

    final navigationItems = [
      {'icon': Icons.home_outlined, 'selectedIcon': Icons.home, 'label': languageProvider.tr('home')},
      {'icon': Icons.folder_outlined, 'selectedIcon': Icons.folder, 'label': languageProvider.tr('records')},
      {'icon': Icons.history_outlined, 'selectedIcon': Icons.history, 'label': languageProvider.tr('medical_history')},
      {'icon': Icons.people_outline, 'selectedIcon': Icons.people, 'label': languageProvider.tr('family')},
      {'icon': Icons.medical_services_outlined, 'selectedIcon': Icons.medical_services, 'label': languageProvider.tr('ai_assistant')},
    ];

    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: navigationItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item['icon'] as IconData),
              selectedIcon: Icon(item['selectedIcon'] as IconData),
              label: item['label'] as String,
            ),
          )
          .toList(),
    );
  }
}

/// Dashboard tab showing health summary
class _DashboardTab extends StatelessWidget {
  final bool showAppBar;
  const _DashboardTab({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final healthRecordProvider = context.watch<HealthRecordProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return CustomScrollView(
      slivers: [
        if (showAppBar) // Conditionally render SliverAppBar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.tr('welcome_back'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textWhite.withOpacity(0.9),
                      ),
                ),
                Text(
                  authProvider.user?.fullName ?? languageProvider.tr('user'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
            ],
          ),

        // Content
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Date card
              _buildDateCard(context),
              const SizedBox(height: 24),

    // Health Metrics (BMI & BMR)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return _buildHealthMetrics(context, authProvider, languageProvider);
                },
              ),
              const SizedBox(height: 24),

              // Summary cards
              _buildSummaryCards(context, healthRecordProvider, familyProvider, languageProvider, isMobile),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(context, isMobile, languageProvider),
              const SizedBox(height: 24),

              // Recent documents
              _buildRecentDocuments(context, healthRecordProvider, languageProvider),
              const SizedBox(height: 24),

              // Health tips
              _buildHealthTips(context, languageProvider),
            ]),
          ),
        ),
      ],
    );
  }

  /// Build date card
  Widget _buildDateCard(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppColors.textWhite,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            dateFormat.format(now),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build health metrics section (BMI & BMR)
  Widget _buildHealthMetrics(
    BuildContext context,
    AuthProvider authProvider,
    LanguageProvider languageProvider,
  ) {
    final user = authProvider.user;
    final bmi = user?.bmi;
    final bmr = user?.bmr;
    final bmiCategory = user?.bmiCategory;

    // If no health data, show prompt to add it
    if (bmi == null || bmr == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Get.to(() => const HealthCalculatorScreen());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.primary, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.tr('track_health_metrics'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.tr('add_height_weight'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }

    // Show health metrics
    final bmiColor = _getBMIColor(bmi);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('health_metrics'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.analytics_outlined,
                title: languageProvider.tr('bmi'),
                value: bmi.toStringAsFixed(1),
                subtitle: bmiCategory ?? '',
                color: bmiColor,
                onTap: () {
                  Get.to(() => const HealthCalculatorScreen());
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.local_fire_department_outlined,
                title: languageProvider.tr('bmr'),
                value: bmr.toStringAsFixed(0),
                subtitle: 'kcal/day',
                color: AppColors.healthBlue,
                onTap: () {
                  Get.to(() => const HealthCalculatorScreen());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build individual metric card
  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.healthOrange;
    return AppColors.error;
  }

  /// Build health chart
  Widget _buildHealthChart(
    BuildContext context,
    double bmi,
    double bmr,
    String? bmiCategory,
    LanguageProvider languageProvider,
  ) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [ 
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: bmi,
                  color: _getBMIColor(bmi),
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: bmr,
                  color: AppColors.healthBlue,
                  width: 20,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = languageProvider.tr('bmi');
                      break;
                    case 1:
                      text = languageProvider.tr('bmr');
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(text, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards(
    BuildContext context,
    HealthRecordProvider provider,
    FamilyProvider familyProvider,
    LanguageProvider languageProvider,
    bool isMobile,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildSummaryCard(
          context,
          icon: Icons.description,
          title: languageProvider.tr('documents'),
          value: '${provider.healthRecords.length}',
          color: AppColors.healthBlue,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.medication,
          title: languageProvider.tr('medications'),
          value: '0',
          color: AppColors.healthGreen,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.event,
          title: languageProvider.tr('appointments'),
          value: '0',
          color: AppColors.healthOrange,
        ),
        _buildSummaryCard(
          context,
          icon: Icons.people,
          title: languageProvider.tr('family'),
          value: '${familyProvider.familyMembers.length}',
          color: AppColors.healthPurple,
        ),
      ],
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions(BuildContext context, bool isMobile, LanguageProvider languageProvider) {
    final actions = [
      _QuickAction(
        icon: Icons.add_photo_alternate,
        label: languageProvider.tr('scan_document'),
        color: AppColors.primary,
        onTap: () {
          Get.to(() => const AddHealthRecordScreen());
        },
      ),
      _QuickAction(
        icon: Icons.qr_code_scanner,
        label: languageProvider.tr('scan_qr'),
        color: AppColors.secondary,
        onTap: () {
          Get.to(() => const QRCodeScannerScreen());
        },
      ),
      _QuickAction(
        icon: Icons.share,
        label: languageProvider.tr('share_history'),
        color: AppColors.success,
        onTap: () {
          Get.to(() => const SelectHistoryToShareScreen());
        },
      ),
      _QuickAction(
        icon: Icons.upload_file,
        label: languageProvider.tr('upload_file'),
        color: AppColors.warning,
        onTap: () {
          Get.to(() => const AddHealthRecordScreen());
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('quick_actions'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isMobile ? 1.5 : 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildQuickActionCard(context, action);
          },
        ),
      ],
    );
  }

  /// Build quick action card
  Widget _buildQuickActionCard(BuildContext context, _QuickAction action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 32),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build recent documents section
  Widget _buildRecentDocuments(
    BuildContext context,
    HealthRecordProvider provider,
    LanguageProvider languageProvider,
  ) {
    final recentDocs = provider.healthRecords.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageProvider.tr('recent_documents'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to records tab
              },
              child: Text(languageProvider.tr('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentDocs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    languageProvider.tr('no_documents_yet'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentDocs.map(
            (doc) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.description, color: AppColors.primary),
                ),
                title: Text(doc.title),
                subtitle: Text(doc.documentType),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to document detail
                },
              ),
            ),
          ),
      ],
    );
  }

  /// Build health tips section
  Widget _buildHealthTips(BuildContext context, LanguageProvider languageProvider) {
    return Card(
      color: AppColors.success.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  languageProvider.tr('health_tip'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.languageCode == 'bn'
                  ? 'আপনার স্বাস্থ্য রেকর্ডগুলি সংগঠিত এবং আপডেট রাখতে মনে রাখবেন। নিয়মিত চেক-আপ এবং প্রতিরোধমূলক যত্ন ভাল স্বাস্থ্য বজায় রাখার চাবিকাঠি।'
                  : 'Remember to keep your health records organized and up to date. Regular check-ups and preventive care are key to maintaining good health.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action model
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}



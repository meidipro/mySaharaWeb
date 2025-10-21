import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/family_member.dart';
import '../../providers/family_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';
import 'add_family_member_screen.dart';
import 'add_family_member_via_code_screen.dart';
import 'family_member_detail_screen.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final _familyService = FamilyService();
  String? _myFamilyCode;
  Map<String, dynamic>? _chronicDiseases;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final familyProvider = context.read<FamilyProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    await Future.wait([
      familyProvider.loadFamilyMembersWithProfile(),
      familyProvider.loadFamilyInvites(),
      familyProvider.loadHealthSummary(),
    ]);

    // Load family code and chronic diseases
    if (userId != null) {
      final code = await _familyService.getMyFamilyCode();
      final diseases = await _familyService.getFamilyChronicDiseases(userId);

      if (mounted) {
        setState(() {
          _myFamilyCode = code;
          _chronicDiseases = diseases;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Health'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Get.to(() => const AddFamilyMemberViaCodeScreen())?.then((_) => _loadData());
            },
            tooltip: 'Add via Family Code',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showInviteCodeDialog,
            tooltip: 'Generate Invite Code',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _showRedeemCodeDialog,
            tooltip: 'Enter Invite Code',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<FamilyProvider>(
          builder: (context, familyProvider, child) {
            if (familyProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                // My Family Code Section
                if (_myFamilyCode != null)
                  SliverPadding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _buildMyFamilyCodeCard(),
                    ),
                  ),

                // Health Summary
                if (familyProvider.healthSummary != null)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      0,
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildHealthSummary(
                        context,
                        familyProvider.healthSummary!,
                        isMobile,
                      ),
                    ),
                  ),

                // Chronic Diseases Section
                if (_chronicDiseases != null && _chronicDiseases!['diseases_by_member'].isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _buildChronicDiseasesSection(),
                    ),
                  ),

                // Active Invites
                if (familyProvider.familyInvites.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _buildInvitesSection(
                        context,
                        familyProvider.familyInvites,
                      ),
                    ),
                  ),

                // Family Members List
                SliverPadding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  sliver: familyProvider.familyMembersWithProfile.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final memberProfile =
                                  familyProvider.familyMembersWithProfile[index];
                              return _buildFamilyMemberCard(
                                context,
                                memberProfile,
                                isMobile,
                              );
                            },
                            childCount:
                                familyProvider.familyMembersWithProfile.length,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddFamilyMemberScreen());
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildHealthSummary(
    BuildContext context,
    Map<String, dynamic> summary,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Family Health Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildSummaryCard(
              context,
              icon: Icons.people,
              title: 'Total Members',
              value: '${summary['total_members'] ?? 0}',
              color: AppColors.healthBlue,
            ),
            _buildSummaryCard(
              context,
              icon: Icons.medical_services,
              title: 'Chronic Diseases',
              value: '${summary['members_with_chronic_diseases'] ?? 0}',
              color: AppColors.healthRed,
            ),
            _buildSummaryCard(
              context,
              icon: Icons.medication,
              title: 'On Medication',
              value: '${summary['members_on_medication'] ?? 0}',
              color: AppColors.healthGreen,
            ),
            _buildSummaryCard(
              context,
              icon: Icons.warning,
              title: 'Allergies',
              value: '${summary['members_with_allergies'] ?? 0}',
              color: AppColors.healthOrange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
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

  Widget _buildInvitesSection(
    BuildContext context,
    List<FamilyInvite> invites,
  ) {
    final pendingInvites = invites.where((i) =>
      !i.isUsed && i.expiresAt.isAfter(DateTime.now())
    ).toList();

    if (pendingInvites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Invite Codes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...pendingInvites.map((invite) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.qr_code, color: AppColors.primary),
                ),
                title: Text(
                  invite.inviteCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                subtitle: Text(
                  'Expires: ${DateFormat('MMM dd, HH:mm').format(invite.expiresAt)}'
                  '${invite.relationship != null ? ' • ${invite.relationship}' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invite.inviteCode));
                    Get.snackbar(
                      'Copied',
                      'Invite code copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFamilyMemberCard(
    BuildContext context,
    FamilyMemberWithProfile memberProfile,
    bool isMobile,
  ) {
    final member = memberProfile.member;
    final isLinked = member.linkedUserId != null && member.linkedUserId!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.to(() => FamilyMemberDetailScreen(
                memberId: member.id!,
                memberProfile: memberProfile,
              ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: member.profileImageUrl != null
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? Text(
                            member.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              member.fullName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (isLinked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link, size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Linked',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.relationship,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (memberProfile.email != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            memberProfile.email!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (isLinked) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      icon: Icons.description,
                      label: 'Documents',
                      value: '${memberProfile.documentCount}',
                    ),
                    _buildStatItem(
                      context,
                      icon: Icons.timeline,
                      label: 'Events',
                      value: '${memberProfile.timelineEventCount}',
                    ),
                    if (member.chronicDiseases != null &&
                        member.chronicDiseases!.isNotEmpty)
                      _buildStatItem(
                        context,
                        icon: Icons.medical_services,
                        label: 'Conditions',
                        value: member.chronicDiseases!.split(',').length.toString(),
                      ),
                  ],
                ),
                if (memberProfile.recentDiseases != null &&
                    memberProfile.recentDiseases!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Recent Conditions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: memberProfile.recentDiseases!.take(3).map((disease) {
                      return Chip(
                        label: Text(disease),
                        backgroundColor: AppColors.healthRed.withOpacity(0.1),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: AppColors.healthRed,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 12),
                if (member.dateOfBirth != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.cake,
                    label: 'Date of Birth',
                    value: DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(member.dateOfBirth!)),
                  ),
                if (member.bloodGroup != null)
                  _buildInfoRow(
                    context,
                    icon: Icons.bloodtype,
                    label: 'Blood Group',
                    value: member.bloodGroup!,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No family members yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add family members or share an invite code to connect',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyFamilyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Family Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _myFamilyCode ?? 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_myFamilyCode != null) {
                    Clipboard.setData(ClipboardData(text: _myFamilyCode!));
                    Get.snackbar(
                      'Copied',
                      'Your family code has been copied',
                      backgroundColor: AppColors.success,
                      colorText: AppColors.textWhite,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: 'Copy my code',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share this permanent code with family members to connect',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronicDiseasesSection() {
    if (_chronicDiseases == null || _chronicDiseases!['diseases_by_member'].isEmpty) {
      return const SizedBox.shrink();
    }

    final diseasesByMember = _chronicDiseases!['diseases_by_member'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧬 Family Chronic Diseases',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Important for understanding genetic predisposition',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        ...diseasesByMember.entries.map((entry) {
          final memberName = entry.key;
          final diseases = entry.value as List;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.healthRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.healthRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          memberName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: diseases.map((disease) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.healthRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.healthRed.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          disease.toString(),
                          style: TextStyle(
                            color: AppColors.healthRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteCodeDialog(),
    );
  }

  void _showRedeemCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => _RedeemCodeDialog(),
    );
  }
}

class _InviteCodeDialog extends StatefulWidget {
  @override
  State<_InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<_InviteCodeDialog> {
  String? _selectedRelationship;
  bool _isGenerating = false;
  FamilyInvite? _generatedInvite;

  final List<String> _relationships = [
    'Parent',
    'Child',
    'Sibling',
    'Spouse',
    'Grandparent',
    'Grandchild',
    'Other',
  ];

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);

    final familyProvider = context.read<FamilyProvider>();
    final invite = await familyProvider.createFamilyInvite(
      relationship: _selectedRelationship,
    );

    setState(() {
      _generatedInvite = invite;
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Invite Code'),
      content: _generatedInvite == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select relationship (optional):'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRelationship,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select relationship',
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedRelationship = value);
                  },
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                const SizedBox(height: 16),
                const Text('Share this code with your family member:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _generatedInvite!.inviteCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Expires: ${DateFormat('MMM dd, HH:mm').format(_generatedInvite!.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
      actions: [
        if (_generatedInvite == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (_generatedInvite == null)
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateCode,
            child: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate'),
          )
        else ...[
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: _generatedInvite!.inviteCode),
              );
              Get.snackbar(
                'Copied',
                'Invite code copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Copy Code'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FamilyProvider>().loadFamilyInvites();
            },
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }
}

class _RedeemCodeDialog extends StatefulWidget {
  @override
  State<_RedeemCodeDialog> createState() => _RedeemCodeDialogState();
}

class _RedeemCodeDialogState extends State<_RedeemCodeDialog> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Error', 'Please enter an invite code',
          backgroundColor: AppColors.error, colorText: AppColors.textWhite);
      return;
    }

    setState(() => _isRedeeming = true);

    final familyProvider = context.read<FamilyProvider>();
    final result = await familyProvider.redeemInviteCode(code);

    setState(() => _isRedeeming = false);

    if (result != null && result['success'] == true) {
      Navigator.pop(context);
      Get.snackbar(
        'Success',
        'Family member connected successfully!',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        familyProvider.errorMessage ?? 'Failed to redeem code',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Invite Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the 6-digit code shared by your family member:'),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '000000',
              counterText: '',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isRedeeming ? null : _redeemCode,
          child: _isRedeeming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}

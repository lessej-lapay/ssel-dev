
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../screens/analysis_report_screen.dart';
import '../../../services/soilsafe_ai.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../farmer/presentation/farmer_profile_screen.dart';
import '../../farmer/presentation/farmer_records_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final _sampleSoil = SoilData(
    pH: 6.2,
    moisture: 55,
    temperature: 28,
    ec: 0.8,
    co2: 24,
    texture: 'loam',
    assessedAt: DateTime(2026, 11, 15, 14, 30),
    placeholderClassification: SscClassification.moderatelySuppressive,
  );

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  void _openSampleAnalysis() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisReportScreen(soilData: HomeScreen._sampleSoil),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final displayName = profile?.displayName ?? _farmerName(auth.user?.email);

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _DashboardTab(
            displayName: displayName,
            soil: HomeScreen._sampleSoil,
            onStartScan: _openSampleAnalysis,
          ),
          _SimpleTab(
            icon: Icons.document_scanner_outlined,
            title: 'Soil Scan',
            subtitle:
                'Capture a new field reading when the IoT probe is connected.',
            actionLabel: 'Start New Soil Scan',
            onAction: _openSampleAnalysis,
          ),
          _HistoryTab(ownerUid: profile?.uid ?? auth.user?.uid ?? ''),
          _ProfileTab(profile: profile, email: auth.user?.email ?? 'Farmer'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: SoilSafeColors.primaryGreen.withValues(alpha: 0.22),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.displayName,
    required this.soil,
    required this.onStartScan,
  });

  final String displayName;
  final SoilData soil;
  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GreetingHeader(displayName: displayName),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SscCard(soil: soil),
                const SizedBox(height: 16),
                _LatestAssessmentCard(soil: soil),
                const SizedBox(height: 24),
                Text(
                  'Real-Time Sensor Readings',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E4D2B),
                  ),
                ),
                const SizedBox(height: 12),
                _SensorReadingCard(
                  icon: Icons.science_outlined,
                  label: 'Soil pH',
                  value: soil.pH.toStringAsFixed(1),
                  unit: 'pH',
                ),
                _SensorReadingCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Soil Moisture',
                  value: soil.moisture.toStringAsFixed(0),
                  unit: '%',
                ),
                _SensorReadingCard(
                  icon: Icons.thermostat_outlined,
                  label: 'Soil Temperature',
                  value: soil.temperature.toStringAsFixed(0),
                  unit: '°C',
                ),
                _SensorReadingCard(
                  icon: Icons.bolt_outlined,
                  label: 'Electrical Conductivity (EC)',
                  value: soil.ec.toStringAsFixed(1),
                  unit: 'dS/m',
                ),
                _SensorReadingCard(
                  icon: Icons.co2_outlined,
                  label: 'CO₂ Respiration Indicator',
                  value: soil.co2.toStringAsFixed(0),
                  unit: 'ppm',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onStartScan,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(
                      'Start New Soil Scan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: SoilSafeColors.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your soil health overview',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SscCard extends StatelessWidget {
  const _SscCard({required this.soil});

  final SoilData soil;

  @override
  Widget build(BuildContext context) {
    final report = SoilSafeAI.generateReport(soil);

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soil Suppressiveness Classification',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E4D2B),
            ),
          ),
          const SizedBox(height: 10),
          if (soil.assessedAt != null)
            Text(
              'Latest assessment: ${_formatDashboardDate(soil.assessedAt!)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Classification: ${report.classificationLabel}',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Interpretation:\n${report.interpretation}',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Recommended action:\n${report.recommendedAction}',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
          if (report.isPlaceholder) ...[
            const SizedBox(height: 10),
            Text(
              'Placeholder sample — SSC is not a numerical index and is not yet '
              'produced by a validated model.',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestAssessmentCard extends StatelessWidget {
  const _LatestAssessmentCard({required this.soil});

  final SoilData soil;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest assessment',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E4D2B),
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'SSC',
            value: soil.placeholderClassification?.label ?? 'Not classified',
          ),
          _InfoRow(label: 'Texture', value: soil.texture),
          const _InfoRow(label: 'Field', value: 'Sample plot'),
          _InfoRow(
            label: 'Recorded',
            value: soil.assessedAt == null
                ? 'Sample reading'
                : _formatDashboardDate(soil.assessedAt!),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorReadingCard extends StatelessWidget {
  const _SensorReadingCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DashboardCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: SoilSafeColors.primaryGreen.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1E4D2B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E4D2B),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SimpleTab extends StatelessWidget {
  const _SimpleTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(icon, size: 56, color: const Color(0xFF1E4D2B)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.ownerUid});

  final String ownerUid;

  @override
  Widget build(BuildContext context) {
    if (ownerUid.isEmpty) {
      return const _SimpleTab(
        icon: Icons.history,
        title: 'Scan History',
        subtitle: 'Sign in to view your saved soil assessments.',
      );
    }
    return FarmerRecordsScreen(
      ownerUid: ownerUid,
      title: 'Scan History',
      embedded: true,
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.email, this.profile});

  final String email;
  final AppUser? profile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: SoilSafeColors.primaryGreen.withValues(
                alpha: 0.2,
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Color(0xFF1E4D2B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile?.displayName ?? email,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            if (profile != null) ...[
              const SizedBox(height: 8),
              Text(
                '${profile!.municipality}${profile!.municipality.isNotEmpty && profile!.province.isNotEmpty ? ', ' : ''}${profile!.province}',
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 24),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              onTap: profile == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FarmerProfileScreen(profile: profile!),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.science_outlined),
              title: const Text('My SSC results'),
              onTap: profile == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              FarmerRecordsScreen(ownerUid: profile!.uid),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.memory_outlined),
              title: const Text('My SoilSAFE device'),
              onTap: profile == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              FarmerDevicesScreen(farmerId: profile!.uid),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 24),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthController>().signOut(),
                icon: const Icon(Icons.logout),
                label: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _farmerName(String? email) {
  if (email == null || email.isEmpty) return 'Farmer';
  final local = email.split('@').first;
  if (local.isEmpty) return 'Farmer';
  return '${local[0].toUpperCase()}${local.substring(1)}';
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

String _formatDashboardDate(DateTime value) {
  final hour = value.hour > 12
      ? value.hour - 12
      : (value.hour == 0 ? 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}, $hour:$minute $period';
}

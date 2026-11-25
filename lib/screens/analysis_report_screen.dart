import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/soilsafe_theme.dart';
//import '../features/assessment/domain/ssc_classification.dart';
import '../services/soilsafe_ai.dart';

class AnalysisReportScreen extends StatelessWidget {
  final SoilData soilData;

  const AnalysisReportScreen({super.key, required this.soilData});

  @override
  Widget build(BuildContext context) {
    final report = SoilSafeAI.generateReport(soilData);
    final color = _classificationColor(report.classification);

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(
        title: Text(
          'Soil Suppressiveness Classification Assessment',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    report.classification == SscClassification.suppressive
                        ? Icons.check_circle
                        : (report.classification ==
                                SscClassification.moderatelySuppressive
                            ? Icons.info
                            : Icons.warning),
                    color: color,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Soil Suppressiveness Classification',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.classificationLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (report.isPlaceholder) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Placeholder result — not from a validated SSC model',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.sensors_outlined, 'Measured parameters'),
            _buildContentCard(
              Column(
                children: [
                  _ParameterRow(label: 'Soil pH', value: soilData.pH.toStringAsFixed(1)),
                  _ParameterRow(
                    label: 'Soil moisture',
                    value: '${soilData.moisture.toStringAsFixed(0)}%',
                  ),
                  _ParameterRow(
                    label: 'Soil temperature',
                    value: '${soilData.temperature.toStringAsFixed(0)}°C',
                  ),
                  _ParameterRow(
                    label: 'Electrical conductivity (EC)',
                    value: '${soilData.ec.toStringAsFixed(1)} dS/m',
                  ),
                  _ParameterRow(
                    label: 'CO₂ respiration indicator',
                    value: '${soilData.co2.toStringAsFixed(0)} ppm',
                  ),
                  _ParameterRow(label: 'Soil texture', value: soilData.texture),
                  if (soilData.assessedAt != null)
                    _ParameterRow(
                      label: 'Assessed',
                      value: _formatDateTime(soilData.assessedAt!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(Icons.lightbulb_outline, 'Interpretation'),
            _buildContentCard(
              Text(
                report.interpretation,
                style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader(Icons.recommend_outlined, 'Recommended action'),
            _buildContentCard(
              Text(
                report.recommendedAction,
                style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 20),

            if (report.contributingFactors.isNotEmpty) ...[
              _buildSectionHeader(Icons.analytics_outlined, 'Contributing factors'),
              _buildContentCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.contributingFactors
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 14))),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildSectionHeader(Icons.eco_outlined, 'Recommended management practices'),
            _buildContentCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.managementPractices
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_box_outlined, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 14))),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.gavel, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report.disclaimer,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey[700],
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Widget child) {
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

class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _classificationColor(SscClassification? classification) {
  switch (classification) {
    case SscClassification.suppressive:
      return Colors.green;
    case SscClassification.moderatelySuppressive:
      return Colors.orange;
    case SscClassification.conducive:
      return Colors.red;
    case null:
      return Colors.blueGrey;
  }
}

String _formatDateTime(DateTime value) {
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

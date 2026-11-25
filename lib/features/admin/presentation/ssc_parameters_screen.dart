import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/domain/ssc_system_parameters.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/widgets/auth_chrome.dart';

class SscParametersScreen extends StatelessWidget {
  const SscParametersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assessments = context.read<AssessmentRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('SSC parameters')),
      body: StreamBuilder<SscSystemParameters>(
        stream: assessments.watchSscParameters(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _SscForm(parameters: snapshot.data!);
        },
      ),
    );
  }
}

class _SscForm extends StatefulWidget {
  const _SscForm({required this.parameters});

  final SscSystemParameters parameters;

  @override
  State<_SscForm> createState() => _SscFormState();
}

class _SscFormState extends State<_SscForm> {
  late final TextEditingController _lowPh;
  late final TextEditingController _highPh;
  late final TextEditingController _moisture;
  late final TextEditingController _co2;
  late final TextEditingController _ec;
  late final TextEditingController _clayMoisture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lowPh = TextEditingController(
      text: widget.parameters.placeholderLowPh.toString(),
    );
    _highPh = TextEditingController(
      text: widget.parameters.placeholderHighPh.toString(),
    );
    _moisture = TextEditingController(
      text: widget.parameters.placeholderHighMoisturePercent.toString(),
    );
    _co2 = TextEditingController(
      text: widget.parameters.placeholderLowCo2Ppm.toString(),
    );
    _ec = TextEditingController(
      text: widget.parameters.placeholderHighEcDsPerM.toString(),
    );
    _clayMoisture = TextEditingController(
      text: widget.parameters.placeholderClayMoisturePercent.toString(),
    );
  }

  @override
  void dispose() {
    _lowPh.dispose();
    _highPh.dispose();
    _moisture.dispose();
    _co2.dispose();
    _ec.dispose();
    _clayMoisture.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AssessmentRepository>().saveSscParameters(
            SscSystemParameters(
              placeholderLowPh: double.parse(_lowPh.text),
              placeholderHighPh: double.parse(_highPh.text),
              placeholderHighMoisturePercent: double.parse(_moisture.text),
              placeholderLowCo2Ppm: double.parse(_co2.text),
              placeholderHighEcDsPerM: double.parse(_ec.text),
              placeholderClayMoisturePercent: double.parse(_clayMoisture.text),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSC parameters saved.')),
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers for every field.')),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'These values are structural placeholders. They are not a validated '
          'scientific SSC model.',
          style: GoogleFonts.inter(color: Colors.grey.shade700, height: 1.45),
        ),
        const SizedBox(height: 20),
        _numberField('Low pH placeholder', _lowPh),
        _numberField('High pH placeholder', _highPh),
        _numberField('High moisture % placeholder', _moisture),
        _numberField('Low CO2 ppm placeholder', _co2),
        _numberField('High EC (dS/m) placeholder', _ec),
        _numberField('Clay moisture % placeholder', _clayMoisture),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save parameters'),
          ),
        ),
      ],
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: authInputDecoration(label),
          ),
        ],
      ),
    );
  }
}

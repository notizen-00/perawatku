import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/cards/medical_card.dart';
import '../cubit/complete_profile_cubit.dart';

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CompleteProfileCubit>(),
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _workLocationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _specializationController.dispose();
    _licenseNumberController.dispose();
    _workLocationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocConsumer<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state is CompleteProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Data profil tersimpan. Akun Anda menunggu verifikasi admin.',
              ),
            ),
          );
          context.go('/dashboard');
        }

        if (state is CompleteProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
          );
        }
      },
      builder: (context, state) {
        final submitting = state is CompleteProfileSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lengkapi Profil'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: submitting ? null : () => context.go('/dashboard'),
                child: const Text('Lewati'),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: AppSpacing.screen,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: MedicalCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Data Profesional',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Data ini yang dicek admin sebelum akun Anda '
                              'diverifikasi dan bisa mulai menerima order.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _Field(
                              controller: _specializationController,
                              label: 'Spesialisasi',
                              icon: Icons.medical_information_outlined,
                              enabled: !submitting,
                              required: false,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _Field(
                              controller: _licenseNumberController,
                              label: 'Nomor STR/SIP',
                              icon: Icons.verified_user_outlined,
                              enabled: !submitting,
                              required: false,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _Field(
                              controller: _workLocationController,
                              label: 'Lokasi kerja',
                              icon: Icons.location_on_outlined,
                              enabled: !submitting,
                              required: false,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    controller: _experienceController,
                                    label: 'Pengalaman (thn)',
                                    icon: Icons.timeline_outlined,
                                    keyboardType: TextInputType.number,
                                    enabled: !submitting,
                                    required: false,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _Field(
                                    controller: _feeController,
                                    label: 'Tarif konsultasi',
                                    icon: Icons.payments_outlined,
                                    keyboardType: TextInputType.number,
                                    enabled: !submitting,
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _Field(
                              controller: _bioController,
                              label: 'Bio singkat',
                              icon: Icons.notes_outlined,
                              enabled: !submitting,
                              required: false,
                              maxLines: 3,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: submitting ? null : () => _submit(context),
                                icon: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded),
                                label: Text(
                                  submitting ? 'Menyimpan...' : 'Simpan & Kirim untuk Verifikasi',
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Bisa juga dilengkapi nanti lewat menu Akun.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<CompleteProfileCubit>().submit(
      specialization: _emptyToNull(_specializationController.text),
      licenseNumber: _emptyToNull(_licenseNumberController.text),
      workLocation: _emptyToNull(_workLocationController.text),
      yearsOfExperience: int.tryParse(_experienceController.text.trim()),
      consultationFee: double.tryParse(_feeController.text.trim()),
      bio: _emptyToNull(_bioController.text),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    this.keyboardType,
    this.required = true,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final bool required;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: required ? _requiredValidator : null,
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Wajib diisi';
  }
  return null;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

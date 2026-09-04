import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Name, city, optional couple phone / wedding date. Used by onboarding and
/// Profile → Edit. Login stays email OTP — this phone is WhatsApp only.
class ProfileDetailsFields extends StatelessWidget {
  const ProfileDetailsFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.city,
    required this.onCityChanged,
    required this.showCoupleFields,
    this.weddingDate,
    this.onPickWeddingDate,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final CityCode? city;
  final ValueChanged<CityCode> onCityChanged;
  final bool showCoupleFields;
  final DateTime? weddingDate;
  final VoidCallback? onPickWeddingDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.fullNameLabel),
        ),
        const SizedBox(height: 20),
        Text(l10n.cityLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.cityTripoli),
              selected: city == CityCode.tripoli,
              onSelected: (_) => onCityChanged(CityCode.tripoli),
              selectedColor: AppColors.burgundy,
              labelStyle: TextStyle(
                color: city == CityCode.tripoli
                    ? AppColors.onBurgundy
                    : AppColors.ink,
              ),
            ),
            ChoiceChip(
              label: Text(l10n.cityBenghazi),
              selected: city == CityCode.benghazi,
              onSelected: (_) => onCityChanged(CityCode.benghazi),
              selectedColor: AppColors.burgundy,
              labelStyle: TextStyle(
                color: city == CityCode.benghazi
                    ? AppColors.onBurgundy
                    : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            labelText: l10n.phoneLabel,
            hintText: l10n.phoneHint,
            prefixText: '${l10n.phonePrefix} ',
            helperText: l10n.phoneForWhatsappHint,
            helperMaxLines: 3,
          ),
        ),
        if (showCoupleFields) ...[
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.weddingDateLabel),
            subtitle: Text(
              weddingDate == null
                  ? l10n.pickDate
                  : weddingDate!.toIso8601String().split('T').first,
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: onPickWeddingDate,
          ),
        ],
      ],
    );
  }
}

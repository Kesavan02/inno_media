import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tactile_bounce.dart';
import '../../domain/entities/form_field_config_entity.dart';

class FieldRendererFactory extends StatelessWidget {
  final FormFieldConfigEntity field;
  final dynamic value;
  final String? errorText;
  final Map<String, dynamic> allFormValues;
  final Function(dynamic newValue) onChanged;

  const FieldRendererFactory({
    super.key,
    required this.field,
    required this.value,
    this.errorText,
    required this.allFormValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.phone:
      case FormFieldType.password:
      case FormFieldType.textarea:
        return _buildTextInput(context);

      case FormFieldType.number:
        return _buildNumberInput(context);

      case FormFieldType.date:
        return _buildDatePicker(context);

      case FormFieldType.time:
        return _buildTimePicker(context);

      case FormFieldType.radio:
        return _buildRadioGroup(context);

      case FormFieldType.dropdown:
        return _buildDropdown(context);

      case FormFieldType.checkbox:
        return _buildCheckboxGroup(context);

      case FormFieldType.checkboxSingle:
        return _buildSingleCheckbox(context);

      case FormFieldType.slider:
        return _buildSlider(context);

      case FormFieldType.switchType:
        return _buildSwitch(context);

      case FormFieldType.file:
        return _buildFilePicker(context);

      case FormFieldType.image:
        return _buildImagePicker(context);

      case FormFieldType.unknown:
        return const SizedBox.shrink();
    }
  }

  // --- 1. Text Inputs (Text, Email, Phone, Password, Textarea) ---
  Widget _buildTextInput(BuildContext context) {
    final isPassword = field.type == FormFieldType.password;
    final isTextarea = field.type == FormFieldType.textarea;
    final isPhone = field.type == FormFieldType.phone;
    final isEmail = field.type == FormFieldType.email;

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: StatefulBuilder(
        builder: (context, setFieldState) {
          return TextFormField(
            initialValue: value?.toString() ?? '',
            obscureText: isPassword,
            maxLines: isTextarea ? 4 : 1,
            maxLength: field.maxLength,
            keyboardType: isPhone
                ? TextInputType.phone
                : isEmail
                    ? TextInputType.emailAddress
                    : isTextarea
                        ? TextInputType.multiline
                        : TextInputType.text,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: field.placeholder.isNotEmpty ? field.placeholder : 'Enter ${field.label.toLowerCase()}',
              counterText: isTextarea ? null : '',
              prefixIcon: Icon(
                isPhone
                    ? Icons.phone_android_rounded
                    : isEmail
                        ? Icons.alternate_email_rounded
                        : isPassword
                            ? Icons.lock_outline_rounded
                            : isTextarea
                                ? Icons.notes_rounded
                                : Icons.edit_note_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            onChanged: (val) => onChanged(val),
          );
        },
      ),
    );
  }

  // --- 2. Number Input ---
  Widget _buildNumberInput(BuildContext context) {
    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTypography.bodyLarge,
        decoration: InputDecoration(
          hintText: field.placeholder.isNotEmpty ? field.placeholder : 'e.g. 25',
          prefixIcon: const Icon(Icons.pin_rounded, size: 20, color: AppColors.textSecondary),
          suffixText: field.min != null && field.max != null ? '${field.min!.toInt()}–${field.max!.toInt()}' : null,
          suffixStyle: AppTypography.bodySmall,
        ),
        onChanged: (val) {
          final parsed = double.tryParse(val);
          onChanged(parsed);
        },
      ),
    );
  }

  // --- 3. Date Picker ---
  Widget _buildDatePicker(BuildContext context) {
    final selectedDate = value is DateTime
        ? value as DateTime
        : (value is String ? DateTime.tryParse(value as String) : null);

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: TactileBounce(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime(2000, 1, 1),
            firstDate: DateTime(1950),
            lastDate: now,
            builder: (context, child) {
              return Theme(data: Theme.of(context), child: child!);
            },
          );
          if (picked != null) {
            onChanged(DateFormat('yyyy-MM-dd').format(picked));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null
                        ? DateFormat.yMMMd().format(selectedDate)
                        : (field.placeholder.isNotEmpty ? field.placeholder : 'Select date of birth'),
                    style: selectedDate != null
                        ? AppTypography.bodyLarge
                        : AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. Time Picker ---
  Widget _buildTimePicker(BuildContext context) {
    final timeStr = value?.toString();

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: TactileBounce(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 9, minute: 0),
          );
          if (picked != null && context.mounted) {
            final formatted = picked.format(context);
            onChanged(formatted);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    timeStr != null && timeStr.isNotEmpty ? timeStr : 'Select preferred time',
                    style: timeStr != null && timeStr.isNotEmpty
                        ? AppTypography.bodyLarge
                        : AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Radio Group ---
  Widget _buildRadioGroup(BuildContext context) {
    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: field.options.map((opt) {
          final isSelected = value == opt;
          return TactileBounce(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 6. Dropdown (with Dependency Support) ---
  Widget _buildDropdown(BuildContext context) {
    final availableOptions = field.getDynamicOptions(allFormValues);
    final isDependencyMet = field.dependsOn == null || availableOptions.isNotEmpty;

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: errorText != null ? AppColors.error : AppColors.border,
            width: 1.0,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: availableOptions.contains(value) ? value as String : null,
            hint: Text(
              !isDependencyMet && field.dependsOn != null
                  ? 'Please select ${field.dependsOn} first'
                  : 'Select ${field.label.toLowerCase()}',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            dropdownColor: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            items: availableOptions.map((opt) {
              return DropdownMenuItem<String>(
                value: opt,
                child: Text(opt, style: AppTypography.bodyLarge),
              );
            }).toList(),
            onChanged: isDependencyMet
                ? (newVal) {
                    if (newVal != null) onChanged(newVal);
                  }
                : null,
          ),
        ),
      ),
    );
  }

  // --- 7. Checkbox Group (Multi-select) ---
  Widget _buildCheckboxGroup(BuildContext context) {
    final selectedList = value is List ? List<String>.from(value as List) : <String>[];

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: field.options.map((opt) {
          final isChecked = selectedList.contains(opt);
          return TactileBounce(
            onTap: () {
              final updated = List<String>.from(selectedList);
              if (isChecked) {
                updated.remove(opt);
              } else {
                updated.add(opt);
              }
              onChanged(updated);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isChecked ? AppColors.secondary.withOpacity(0.2) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isChecked ? AppColors.secondaryLight : AppColors.border,
                  width: isChecked ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isChecked ? AppColors.secondaryLight : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isChecked ? Colors.white : AppColors.textPrimary,
                      fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 8. Single Checkbox (Terms & Conditions) ---
  Widget _buildSingleCheckbox(BuildContext context) {
    final isChecked = value == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TactileBounce(
          onTap: () => onChanged(!isChecked),
          child: Row(
            children: [
              Icon(
                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isChecked ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isChecked ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4),
            child: Text(errorText!, style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
          ),
      ],
    );
  }

  // --- 9. Slider (Years of Experience) ---
  Widget _buildSlider(BuildContext context) {
    final double minVal = field.min ?? 0.0;
    final double maxVal = field.max ?? 15.0;
    final double currentVal = value is num ? (value as num).toDouble() : minVal;

    return _FormFieldWrapper(
      label: '${field.label}: ${currentVal.toInt()} years',
      required: field.required,
      errorText: errorText,
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primaryLight,
              overlayColor: AppColors.primary.withOpacity(0.2),
              valueIndicatorColor: AppColors.surfaceElevated,
              valueIndicatorTextStyle: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            child: Slider(
              value: currentVal.clamp(minVal, maxVal),
              min: minVal,
              max: maxVal,
              divisions: field.divisions ?? (maxVal - minVal).toInt(),
              label: '${currentVal.toInt()} yrs',
              onChanged: (val) => onChanged(val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${minVal.toInt()} yrs', style: AppTypography.bodySmall),
                Text('${maxVal.toInt()} yrs', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 10. Switch (Married Toggle) ---
  Widget _buildSwitch(BuildContext context) {
    final isSwitched = value == true;

    return _FormFieldWrapper(
      label: '',
      required: false,
      errorText: errorText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSwitched ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isSwitched ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(field.label, style: AppTypography.titleLarge.copyWith(fontSize: 15)),
              ],
            ),
            Switch(
              value: isSwitched,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
              inactiveThumbColor: AppColors.textMuted,
              inactiveTrackColor: AppColors.surfaceElevated,
              onChanged: (val) => onChanged(val),
            ),
          ],
        ),
      ),
    );
  }

  // --- 11. File Picker (Upload Resume) ---
  Widget _buildFilePicker(BuildContext context) {
    final fileName = value?.toString();

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: TactileBounce(
        onTap: () {
          // Provide interactive file selection simulator with realistic documents
          _showFilePickerSheet(context);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.upload_file_rounded, color: AppColors.secondaryLight, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName != null && fileName.isNotEmpty ? fileName : 'Choose resume document',
                      style: AppTypography.titleLarge.copyWith(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accepted: ${field.allowedExtensions.join(", ").toUpperCase()}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              if (fileName != null && fileName.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () => onChanged(null),
                )
              else
                const Icon(Icons.folder_open_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilePickerSheet(BuildContext context) {
    final sampleFiles = [
      'John_Doe_Senior_Flutter_Engineer.pdf',
      'Curriculum_Vitae_2026.docx',
      'Portfolio_Architecture_Lead.pdf',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select File from Storage', style: AppTypography.headlineMedium),
                const SizedBox(height: 14),
                ...sampleFiles.map((f) {
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    title: Text(f, style: AppTypography.bodyLarge),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      onChanged(f);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 12. Image Picker (Profile Picture) ---
  Widget _buildImagePicker(BuildContext context) {
    final imageUri = value?.toString();

    return _FormFieldWrapper(
      label: field.label,
      required: field.required,
      errorText: errorText,
      child: Row(
        children: [
          // Circular Avatar preview
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: imageUri != null && imageUri.isNotEmpty ? NetworkImage(imageUri) : null,
                child: imageUri == null || imageUri.isEmpty
                    ? const Icon(Icons.person_rounded, size: 36, color: AppColors.textMuted)
                    : null,
              ),
              if (imageUri != null && imageUri.isNotEmpty)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onChanged(null),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TactileBounce(
                  onTap: () => _showImagePickerSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Choose Photo', style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('PNG, JPG, or WEBP up to 5MB', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerSheet(BuildContext context) {
    final sampleImages = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Profile Avatar', style: AppTypography.headlineMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: sampleImages.map((img) {
                    return TactileBounce(
                      onTap: () {
                        onChanged(img);
                        Navigator.of(context).pop();
                      },
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(img),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper container wrapping label, asterisk for required, and error messages
class _FormFieldWrapper extends StatelessWidget {
  final String label;
  final bool required;
  final String? errorText;
  final Widget child;

  const _FormFieldWrapper({
    required this.label,
    required this.required,
    this.errorText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(label, style: AppTypography.labelLarge),
              if (required) ...[
                const SizedBox(width: 4),
                Text('*', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        child,
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorText!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

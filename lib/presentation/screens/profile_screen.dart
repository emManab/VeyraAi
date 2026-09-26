import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  String _picturePath = '';

  @override
  void initState() {
    super.initState();
    final st = context.read<SettingsBloc>().state;
    if (st is SettingsReady) {
      _nameCtrl.text = st.profileName;
      _picturePath = st.profilePicture;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      // Copy to local app directory
      final dir = await getApplicationDocumentsDirectory();
      final ext = p.extension(xfile.path);
      final newPath = p.join(dir.path, 'profile_${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(xfile.path).copy(newPath);
      
      setState(() {
        _picturePath = newPath;
      });
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      context.read<SettingsBloc>().add(SettingsProfileSaved(name, _picturePath));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.heading2),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: _picturePath.isNotEmpty ? FileImage(File(_picturePath)) : null,
                    child: _picturePath.isEmpty
                        ? Text(
                            _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'M',
                            style: AppTypography.heading1.copyWith(color: AppColors.primary),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
                ),
                onPressed: _save,
                child: Text('Save Profile', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

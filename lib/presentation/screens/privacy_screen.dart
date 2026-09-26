import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../blocs/conversation/conversation_bloc.dart';
import '../blocs/conversation/conversation_event.dart';
import '../blocs/conversation/conversation_state.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String _storageSize = 'Calculating...';
  bool _micGranted = false;
  bool _cameraGranted = false;
  bool _photosGranted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _calculateStorage();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.status;
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status;
    
    if (mounted) {
      setState(() {
        _micGranted = mic.isGranted;
        _cameraGranted = camera.isGranted;
        _photosGranted = photos.isGranted;
      });
    }
  }

  Future<void> _calculateStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;
      if (appDir.existsSync()) {
        final List<FileSystemEntity> files = appDir.listSync(recursive: true);
        for (var file in files) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
      }
      
      final kb = totalSize / 1024;
      final mb = kb / 1024;
      
      if (mounted) {
        setState(() {
          if (mb > 1) {
            _storageSize = '${mb.toStringAsFixed(2)} MB';
          } else {
            _storageSize = '${kb.toStringAsFixed(2)} KB';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _storageSize = 'Unknown';
        });
      }
    }
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Data', style: AppTypography.titleLarge),
        content: Text('Are you sure you want to delete all conversations, settings, and local data? This cannot be undone.', style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.buttonSmall),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final state = context.read<ConversationBloc>().state;
              if (state is ConversationListLoaded) {
                for (var conv in state.conversations) {
                  context.read<ConversationBloc>().add(ConversationDeleted(conv.id));
                }
              }
              // Clear hive settings box just in case
              try {
                final box = await Hive.openBox('app_settings');
                await box.clear();
              } catch (_) {}
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All data deleted successfully'), backgroundColor: AppColors.primary),
                );
                _calculateStorage();
              }
            },
            child: Text('Delete', style: AppTypography.buttonSmall),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Security', style: AppTypography.heading2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSectionCard(
            context,
            title: 'Storage & Data',
            children: [
              BlocBuilder<ConversationBloc, ConversationState>(
                builder: (context, state) {
                  int count = 0;
                  if (state is ConversationListLoaded) {
                    count = state.conversations.length;
                  }
                  return ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                    title: Text('Conversations', style: AppTypography.body),
                    trailing: Text('$count', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
                  );
                }
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.sd_storage_outlined, color: AppColors.primary),
                title: Text('Local Storage Used', style: AppTypography.body),
                trailing: Text(_storageSize, style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Delete All Data', style: AppTypography.body.copyWith(color: AppColors.error)),
                onTap: _clearData,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildSectionCard(
            context,
            title: 'Permissions',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.mic_none, color: AppColors.primary),
                title: Text('Microphone', style: AppTypography.body),
                subtitle: Text('Used for voice messages', style: AppTypography.caption),
                value: _micGranted,
                onChanged: (val) async {
                  if (val) {
                    final status = await Permission.microphone.request();
                    setState(() => _micGranted = status.isGranted);
                  } else {
                    openAppSettings();
                  }
                },
                activeThumbColor: AppColors.primary,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Camera', style: AppTypography.body),
                subtitle: Text('Used to take photos', style: AppTypography.caption),
                value: _cameraGranted,
                onChanged: (val) async {
                  if (val) {
                    final status = await Permission.camera.request();
                    setState(() => _cameraGranted = status.isGranted);
                  } else {
                    openAppSettings();
                  }
                },
                activeThumbColor: AppColors.primary,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Photos & Files', style: AppTypography.body),
                subtitle: Text('Used to attach images and documents', style: AppTypography.caption),
                value: _photosGranted,
                onChanged: (val) async {
                  if (val) {
                    final status = await Permission.photos.request();
                    setState(() => _photosGranted = status.isGranted);
                  } else {
                    openAppSettings();
                  }
                },
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'Your data is stored locally on your device.\nAPI Keys are stored securely in encrypted storage.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: isDark ? AppColors.surfaceDarkCard : AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

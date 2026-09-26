import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/attachment.dart';

class MessageComposer extends StatefulWidget {
  final bool isLoading;
  final void Function(String text, List<Attachment> attachments) onSend;

  const MessageComposer({
    super.key,
    required this.isLoading,
    required this.onSend,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _ctrl = TextEditingController();
  final List<Attachment> _attachments = [];
  final _picker = ImagePicker();
  
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() {}); // trigger rebuild to toggle mic/send button
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (val) => setState(() => _isListening = false),
      onStatus: (val) => setState(() => _isListening = val == 'listening'),
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted && _speechEnabled) {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _ctrl.text = result.recognizedWords;
          });
        },
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if ((text.isNotEmpty || _attachments.isNotEmpty) && !widget.isLoading) {
      widget.onSend(text, List.from(_attachments));
      _ctrl.clear();
      setState(() {
        _attachments.clear();
      });
    }
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      setState(() {
        _attachments.add(Attachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: xfile.path,
          type: AttachmentType.image,
          mimeType: 'image/jpeg',
          name: p.basename(xfile.path),
        ));
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'csv', 'json', 'dart', 'yaml'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachments.add(Attachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          path: result.files.single.path!,
          type: AttachmentType.document,
          name: result.files.single.name,
        ));
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.image, color: AppColors.primary),
              title: Text('Image'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file, color: AppColors.primary),
              title: Text('Document'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_attachments.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, i) {
                    final a = _attachments[i];
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          margin: const EdgeInsets.only(top: 8, right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryLight),
                            image: a.type == AttachmentType.image
                                ? DecorationImage(image: FileImage(File(a.path)), fit: BoxFit.cover)
                                : null,
                            color: a.type == AttachmentType.document ? AppColors.primaryLight.withValues(alpha: 0.2) : null,
                          ),
                          child: a.type == AttachmentType.document
                              ? Center(child: Icon(Icons.insert_drive_file, color: AppColors.primary))
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _attachments.removeAt(i));
                            },
                            child: Container(
                              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                  onPressed: widget.isLoading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDarkCard : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Message Veyra AI...',
                        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : (widget.isLoading ? AppColors.textTertiary : AppColors.primary),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _ctrl.text.isEmpty && !widget.isLoading && _attachments.isEmpty && !_isListening
                          ? Icons.mic
                          : (_isListening ? Icons.stop : Icons.arrow_upward),
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: widget.isLoading 
                        ? null 
                        : (_isListening 
                            ? _stopListening 
                            : (_ctrl.text.isEmpty && _attachments.isEmpty ? _startListening : _submit)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

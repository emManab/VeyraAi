import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/attachment.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0, bottom: 4.0),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 14,
                child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.userBubbleGradient : null,
                color: isUser
                    ? null
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDarkCard
                        : AppColors.surfaceWhite),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser ? AppShadows.subtle : null,
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: message.attachments.map((a) {
                          if (a.type == AttachmentType.image) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(a.path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.white24 : AppColors.primaryLight.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.insert_drive_file, size: 16, color: isUser ? Colors.white : AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.name ?? a.path.split('/').last,
                                    style: AppTypography.caption.copyWith(color: isUser ? Colors.white : AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }
                        }).toList(),
                      ),
                    ),
                  MarkdownBody(
                    data: message.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTypography.bodyLarge.copyWith(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      code: AppTypography.body.copyWith(
                        fontFamily: 'monospace',
                        backgroundColor: isUser
                            ? Colors.black.withValues(alpha: 0.2)
                            : AppColors.textPrimary.withValues(alpha: 0.1),
                        color: isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser
                            ? Colors.black.withValues(alpha: 0.2)
                            : AppColors.surfaceDarkCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.jm().format(message.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: isUser ? Colors.white70 : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: Icon(Icons.copy, size: 12, color: AppColors.textTertiary),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 28), // padding equivalent to avatar
        ],
      ),
    );
  }
}

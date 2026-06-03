import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/chat_message.dart';
import '../../../models/category.dart';
import '../../../services/database/local_db.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  bool get isUser => message.senderRole == 'user';

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildOyenMiniAvatar(),
            const SizedBox(width: AppSpacing.space2),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: size.width * 0.75),
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppColors.primary 
                    : AppColors.neutral0,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser 
                    ? null 
                    : Border.all(color: AppColors.neutral200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message Content Text
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : AppColors.neutral900,
                      height: 1.4,
                    ),
                  ),

                  // Transaction Receipt Widget (if linked)
                  if (message.transactionId != null) ...[
                    const SizedBox(height: 8),
                    _buildTransactionReceipt(message.transactionId!),
                  ],

                  const SizedBox(height: 4),

                  // Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: isUser 
                              ? Colors.white.withValues(alpha: 0.7) 
                              : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.space2),
            _buildUserMiniAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildOyenMiniAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Text(
        '🐱',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildUserMiniAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }

  Widget _buildTransactionReceipt(int transactionId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: LocalDb.instance.getTransactionWithCategory(transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.space2),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                SizedBox(width: 8),
                Text('Memuat transaksi...', style: TextStyle(fontSize: 11)),
              ],
            ),
          );
        }

        final txData = snapshot.data;
        if (txData == null) {
          return const SizedBox.shrink();
        }

        final amount = txData['amount_idr'] as int;
        final categoryName = txData['category_name'] as String;
        final colorHex = txData['color_hex'] as String?;
        final iconName = txData['icon_name'] as String?;
        final desc = txData['description'] as String?;
        final catColor = CategoryModel.getColor(colorHex);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryModel.getIconData(iconName),
                  color: catColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc ?? categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount & Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.danger, // expenses are negative/red
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 10),
                      SizedBox(width: 2),
                      Text(
                        'Tercatat',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

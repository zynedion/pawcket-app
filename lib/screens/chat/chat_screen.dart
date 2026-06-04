import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/mr_oyen_avatar.dart';
import '../../services/speech/speech_service.dart';
import 'widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleSpeechInput() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      setState(() {
        _isListening = true;
      });

      try {
        await _speechService.startListening(
          onResult: (text) {
            setState(() {
              _isListening = false;
              _messageController.text = text;
            });
          },
          onTimeout: () {
            setState(() {
              _isListening = false;
            });
          },
        );
      } catch (e) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Izin mikrofon ditolak atau bermasalah: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _messageController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    // Auto scroll to bottom when messages count changes
    final messages = chatState.currentSession?.messages ?? [];
    if (messages.length != _prevMessageCount) {
      _prevMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // Scroll to bottom when keyboard appears or loading completes
    if (chatState.isSending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Row(
          children: [
            MrOyenAvatar(size: 40, expression: chatState.isSending ? 'thinking' : chatState.currentMood),
            const SizedBox(width: AppSpacing.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mr. Oyen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  chatState.isSending 
                      ? 'Oyen sedang mengetik...' 
                      : (_isListening ? 'Mendengarkan...' : 'Online (Snoozing)'),
                  style: TextStyle(
                    fontSize: 11,
                    color: chatState.isSending 
                        ? AppColors.primary 
                        : (_isListening ? AppColors.danger : AppColors.neutral500),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.neutral900),
            onSelected: (value) {
              if (value == 'new_session') {
                ref.read(chatProvider.notifier).startNewSession();
              } else if (value == 'clear_history') {
                _showClearHistoryDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_session',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20, color: AppColors.neutral900),
                    SizedBox(width: 8),
                    Text('Sesi Baru'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Hapus Riwayat', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error Message Banner (if any)
            if (chatState.errorMessage != null)
              Container(
                width: double.infinity,
                color: AppColors.danger.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chatState.errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Message History Area
            Expanded(
              child: chatState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space4,
                            vertical: AppSpacing.space2,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return ChatBubble(message: messages[index]);
                          },
                        )),
            ),

            // Typing Indicator
            if (chatState.isSending) _buildTypingIndicator(),

            // Chat Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MrOyenAvatar(size: 100, expression: 'lazyass'),
          const SizedBox(height: AppSpacing.space4),
          const Text(
            'Mulai chat dengan Mr. Oyen!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Tulis sesuatu seperti "beli kopi 25rb" untuk mencatat pengeluaran Anda atau tanyakan "berapa total pengeluaran saya?"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: const Text('🐱', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neutral0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 3),
                _buildDot(150),
                const SizedBox(width: 3),
                _buildDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return _FlashingDot(delayMs: delayMs);
  }

  Widget _buildInputArea() {
    final chatState = ref.watch(chatProvider);
    final settingsState = ref.watch(settingsProvider);
    final enableVoice = settingsState.preferences?.enableVoiceInput ?? true;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        border: Border(
          top: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Voice Input Dictation Button
          if (enableVoice) ...[
            IconButton(
              icon: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: _isListening ? AppColors.danger : AppColors.secondary,
              ),
              onPressed: chatState.isSending ? null : _toggleSpeechInput,
              tooltip: 'Suara ke Teks',
            ),
            const SizedBox(width: 4),
          ],

          // Message Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !chatState.isSending,
              style: const TextStyle(color: AppColors.neutral900, fontSize: 15),
              decoration: InputDecoration(
                hintText: _isListening ? 'Mendengarkan...' : 'Ketik pesan Anda...',
                hintStyle: const TextStyle(color: AppColors.neutral500),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppColors.neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: chatState.isSending ? null : _send,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chatState.isSending ? AppColors.neutral200 : AppColors.primary,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat percakapan dengan Mr. Oyen? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Micro-animation helper for typing dots
class _FlashingDot extends StatefulWidget {
  final int delayMs;
  const _FlashingDot({required this.delayMs});

  @override
  State<_FlashingDot> createState() => _FlashingDotState();
}

class _FlashingDotState extends State<_FlashingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.neutral500,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../../services/api/nlp_parser.dart';
import '../../services/database/local_db.dart';
import '../../services/speech/speech_service.dart';
import '../../services/widget/widget_service.dart';

class QuickInputView extends ConsumerStatefulWidget {
  final bool startWithVoice;

  const QuickInputView({
    super.key,
    this.startWithVoice = false,
  });

  @override
  ConsumerState<QuickInputView> createState() => _QuickInputViewState();
}

class _QuickInputViewState extends ConsumerState<QuickInputView> {
  final TextEditingController _textController = TextEditingController();
  final SpeechService _speechService = SpeechService();
  final NLPParser _nlpParser = NLPParser();
  final LocalDb _db = LocalDb.instance;

  bool _isLoading = false;
  bool _isListening = false;
  String _oyenExpression = 'lazyass_oyen';
  String? _errorMessage;
  String _statusText = 'Ready to log';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.startWithVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toggleListening();
      });
    }
  }

  Future<void> _initSpeech() async {
    await _speechService.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _oyenExpression = 'lazyass_oyen';
      });
      await _speechService.stopListening();
    } else {
      setState(() {
        _isListening = true;
        _errorMessage = null;
        _statusText = 'Listening...';
        _oyenExpression = 'mischievous_oyen';
      });
      try {
        await _speechService.startListening(
          onResult: (transcribed) {
            setState(() {
              _isListening = false;
              _textController.text = transcribed;
              _statusText = 'Speech captured';
              _oyenExpression = 'lazyass_oyen';
            });
            _processInput(transcribed);
          },
          onTimeout: () {
            setState(() {
              _isListening = false;
              _statusText = 'Ready to log';
              _oyenExpression = 'lazyass_oyen';
            });
          },
        );
      } catch (e) {
        setState(() {
          _isListening = false;
          _errorMessage = 'Microphone permission not granted';
          _oyenExpression = 'angry_oyen';
          _statusText = 'Permission Error';
        });
      }
    }
  }

  Future<void> _processInput(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusText = 'Asking Mr. Oyen to parse...';
      _oyenExpression = 'thinking_oyen';
    });

    // Update widget in background to show thinking expression
    await WidgetService.setThinkingOyen(
      status: 'Mr. Oyen is thinking...',
      display: 'Parsing: "$text"',
    );

    try {
      final user = await _db.getUser();
      if (user == null) {
        throw Exception('User not registered. Please open the main app first.');
      }
      final userId = user.userId!;

      final parsedTx = await _nlpParser.parseExpenseFromText(text);

      if (parsedTx.error != null) {
        throw Exception(parsedTx.error);
      }

      if (parsedTx.amount <= 0) {
        throw Exception('Amount must be positive');
      }

      // Check/create category mapping
      final categoryId = await _db.verifyCategoryExists(userId, parsedTx.category);
      if (categoryId == null) {
        throw Exception('Could not find category: ${parsedTx.category}');
      }

      // Create transaction model
      final now = DateTime.now().millisecondsSinceEpoch;
      final tx = TransactionModel(
        userId: userId,
        categoryId: categoryId,
        transactionType: 'expense',
        amountIdr: parsedTx.amount,
        description: parsedTx.description,
        vendorName: parsedTx.vendor,
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
        isSyncedToCloud: false,
        nlpConfidence: 1.0,
      );

      // Save to Database
      await _db.insertTransaction(tx);

      setState(() {
        _isLoading = false;
        _oyenExpression = 'smirk_oyen';
        _statusText = 'Logged successfully!';
      });

      // Update widget to show smirk expression and logged amount
      final formattedAmount = '${parsedTx.amount} IDR';
      await WidgetService.setSuccessOyen(
        display: 'Added $formattedAmount for ${parsedTx.category}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Added $formattedAmount to ${parsedTx.category}'),
          backgroundColor: const Color(0xCC4F46E5), // Indigo semi-transparent
        ),
      );

      // Wait 1.5 seconds for user to see the success before closing
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _statusText = 'Error';
        _oyenExpression = 'angry_oyen';
      });

      // Update widget with the error expression
      await WidgetService.setErrorOyen(
        errorText: _errorMessage ?? 'Parsing failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4), // Overlay overlay background
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withOpacity(0.95), // dark neutral-900 glassmorphism
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mascot Display
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Image.asset(
                      'assets/images/$_oyenExpression.png',
                      key: ValueKey(_oyenExpression),
                      height: 120,
                      width: 120,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Text
                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Color(0xFF0EA5E9), // Accent blue
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title Instruction
                  const Text(
                    'Quick Log Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Text input
                  TextField(
                    controller: _textController,
                    autofocus: !widget.startWithVoice,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Makan gado-gado 15k',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2), // Indigo focus
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                    ),
                    onSubmitted: (val) => _processInput(val),
                  ),

                  // Error Message Area
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444), // Danger Red
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close / Cancel Button
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Microphone Button (Voice Trigger)
                      GestureDetector(
                        onTap: _isLoading ? null : _toggleListening,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening 
                              ? const Color(0xFFEF4444) // Red while recording
                              : const Color(0xFF0EA5E9), // Sky Blue otherwise
                            boxShadow: _isListening
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Add/Save Button
                      ElevatedButton(
                        onPressed: _isLoading 
                          ? null 
                          : () => _processInput(_textController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // Indigo
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

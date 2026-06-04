import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/category_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/csv_parser.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  int _currentStep = 0;
  
  // Step 1: Input Data State
  final TextEditingController _textController = TextEditingController();
  String? _fileName;
  String? _fileContent;
  bool _hasHeader = true;
  
  // Step 2: Columns State
  List<List<String>> _parsedRows = [];
  List<String> _headers = [];
  Map<String, int> _columnMapping = {};
  
  // Step 3: Global Category Mapping & Preview State
  List<ParsedCsvRow> _processedRows = [];
  Map<String, CategoryModel> _categoryMappings = {}; // Spreadsheet Category Name -> CategoryModel

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  // --- STEP 1: Process Text or File ---
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final content = String.fromCharCodes(bytes);
          setState(() {
            _fileName = file.name;
            _fileContent = content;
            _textController.clear(); // Clear text field if file is selected
          });
        }
      }
    } catch (e) {
      _showError('Gagal memilih file: $e');
    }
  }

  void _proceedToStep2() {
    final content = _fileName != null ? _fileContent : _textController.text.trim();
    if (content == null || content.isEmpty) {
      _showError('Silakan pilih file atau tempel data spreadsheet terlebih dahulu');
      return;
    }

    try {
      final rows = CsvParser.parseToRows(content);
      if (rows.isEmpty) {
        _showError('Data kosong atau tidak valid');
        return;
      }

      setState(() {
        _parsedRows = rows;
        // Generate mock headers if not provided
        if (_hasHeader) {
          _headers = rows.first;
        } else {
          _headers = List.generate(rows.first.length, (i) => 'Kolom ${i + 1}');
        }
        
        // Auto-detect columns
        _columnMapping = CsvParser.autoDetectHeaders(_headers);
        _currentStep = 1;
      });
    } catch (e) {
      _showError('Gagal memproses data: $e');
    }
  }

  // --- STEP 2: Process Columns ---
  void _proceedToStep3(List<CategoryModel> dbCategories) {
    // Validation: Date and Category are mandatory
    if (!_columnMapping.containsKey('date')) {
      _showError('Kolom Tanggal harus ditentukan');
      return;
    }
    if (!_columnMapping.containsKey('category')) {
      _showError('Kolom Kategori harus ditentukan');
      return;
    }

    // Validation for Amount
    final hasSingleAmount = _columnMapping.containsKey('amount');
    final hasSeparateAmount = _columnMapping.containsKey('income_amount') || _columnMapping.containsKey('expense_amount');
    
    if (!hasSingleAmount && !hasSeparateAmount) {
      _showError('Silakan tentukan kolom Nominal (atau kolom Pemasukan & Pengeluaran secara terpisah)');
      return;
    }

    try {
      final processed = CsvParser.processRows(
        rows: _parsedRows,
        mapping: _columnMapping,
        hasHeader: _hasHeader,
      );

      if (processed.isEmpty) {
        _showError('Tidak ada transaksi yang berhasil diproses dari file');
        return;
      }

      // Find unique category names from CSV
      final uniqueCsvCategories = processed.map((r) => r.category.trim()).toSet();
      
      // Auto-match CSV category strings with DB categories
      final Map<String, CategoryModel> initialMappings = {};
      final expenseOther = dbCategories.firstWhere(
        (c) => c.categoryType == 'other',
        orElse: () => dbCategories.firstWhere(
          (c) => !PredefinedCategory.isIncomeType(c.categoryType),
          orElse: () => dbCategories.first,
        ),
      );
      final incomeOther = dbCategories.firstWhere(
        (c) => c.categoryType == 'other_income',
        orElse: () => dbCategories.firstWhere(
          (c) => PredefinedCategory.isIncomeType(c.categoryType),
          orElse: () => dbCategories.first,
        ),
      );

      for (final csvCat in uniqueCsvCategories) {
        if (csvCat.isEmpty) continue;
        
        // Find isIncome from transactions of this category in processed rows (heuristic)
        final matchingTxs = processed.where((r) => r.category.trim() == csvCat);
        final isIncome = matchingTxs.isNotEmpty && matchingTxs.first.transactionType == 'income';
        
        final matchedDbCat = dbCategories.firstWhere(
          (c) => c.categoryName.toLowerCase() == csvCat.toLowerCase() ||
                 c.categoryType.toLowerCase() == csvCat.toLowerCase(),
          orElse: () => isIncome ? incomeOther : expenseOther,
        );
        initialMappings[csvCat] = matchedDbCat;
      }

      setState(() {
        _processedRows = processed;
        _categoryMappings = initialMappings;
        _currentStep = 2;
      });
    } catch (e) {
      _showError('Gagal memetakan kolom: $e');
    }
  }

  // --- STEP 3: Complete Import ---
  Future<void> _importData() async {
    try {
      final user = await ref.read(historyProvider.notifier).db.getUser();
      if (user == null) {
        _showError('User tidak ditemukan');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Map processed rows to TransactionModel using the global category mapping
      final List<TransactionModel> transactionsToInsert = _processedRows.map((row) {
        final dbCat = _categoryMappings[row.category.trim()] ?? 
            (_selectedFallbackCategory(row.transactionType == 'income'));
        
        return TransactionModel(
          userId: user.userId!,
          categoryId: dbCat.categoryId!,
          transactionType: row.transactionType,
          amountIdr: row.amount,
          description: row.description,
          vendorName: row.vendor,
          transactionDate: row.date?.millisecondsSinceEpoch ?? now,
          createdAt: now,
          updatedAt: now,
          isSyncedToCloud: false,
          nlpConfidence: 1.0, // Imported transactions have high confidence since they are structured
        );
      }).toList();

      final success = await ref.read(historyProvider.notifier).importTransactions(transactionsToInsert);
      
      if (success && mounted) {
        ref.invalidate(dashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor ${transactionsToInsert.length} transaksi!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError('Gagal mengimpor transaksi ke database');
      }
    } catch (e) {
      _showError('Terjadi kesalahan saat mengimpor: $e');
    }
  }

  CategoryModel _selectedFallbackCategory(bool isIncome) {
    final dbCategories = ref.read(categoryProvider).value ?? [];
    if (isIncome) {
      return dbCategories.firstWhere(
        (c) => c.categoryType == 'other_income',
        orElse: () => dbCategories.firstWhere(
          (c) => PredefinedCategory.isIncomeType(c.categoryType),
          orElse: () => dbCategories.first,
        ),
      );
    } else {
      return dbCategories.firstWhere(
        (c) => c.categoryType == 'other',
        orElse: () => dbCategories.firstWhere(
          (c) => !PredefinedCategory.isIncomeType(c.categoryType),
          orElse: () => dbCategories.first,
        ),
      );
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Impor Riwayat Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          data: (dbCategories) {
            return Column(
              children: [
                // Step Indicator Bar
                _buildStepIndicator(),
                
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          ...previousChildren,
                          ?currentChild,
                        ],
                      );
                    },
                    child: _buildCurrentStepView(dbCategories, theme),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat kategori: $err')),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3, horizontal: AppSpacing.space4),
      color: AppColors.neutral0,
      child: Row(
        children: [
          _stepNode(0, 'Unggah'),
          _stepLine(0),
          _stepNode(1, 'Kolom'),
          _stepLine(1),
          _stepNode(2, 'Kategori & Preview'),
        ],
      ),
    );
  }

  Widget _stepNode(int index, String title) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;
    
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone 
                ? AppColors.primary 
                : (isActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.neutral200),
            border: Border.all(
              color: isDone || isActive ? AppColors.primary : AppColors.neutral500,
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : (isDone ? Colors.white : AppColors.neutral500),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: isActive || isDone ? AppColors.neutral900 : AppColors.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int index) {
    final isDone = _currentStep > index;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isDone ? AppColors.primary : AppColors.neutral200,
      ),
    );
  }

  Widget _buildCurrentStepView(List<CategoryModel> dbCategories, ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1View(theme);
      case 1:
        return _buildStep2View(dbCategories, theme);
      case 2:
        return _buildStep3View(dbCategories, theme);
      default:
        return Container();
    }
  }

  // --- STEP 1 VIEW: Upload / Paste ---
  Widget _buildStep1View(ThemeData theme) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Langkah 1: Masukkan Data Keuangan Anda',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space1),
              const Text(
                'Anda dapat memilih file CSV (.csv) dari memori perangkat atau menyalin teks secara langsung dari Google Sheets / Excel dan menempelkannya di bawah ini.',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.space4),
              
              // Option A: Choose file
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        _fileName ?? 'Pilih File CSV/TSV',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      if (_fileName != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('Ketuk untuk mengganti file', style: TextStyle(fontSize: 10, color: AppColors.neutral500)),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.space3),
              const Center(child: Text('— ATAU TEMPELKAN DI SINI —', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral500))),
              const SizedBox(height: AppSpacing.space3),

              // Option B: Paste text
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Tempel data baris spreadsheet di sini...\nContoh:\nTanggal,Kategori,Nominal,Keterangan\n01/05/2026,Makanan,75000,Makan Siang\n02/05/2026,Gaji,5000000,Gaji Mei',
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && _fileName != null) {
                      setState(() {
                        _fileName = null;
                        _fileContent = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Checkbox header
              Row(
                children: [
                  Checkbox(
                    value: _hasHeader,
                    onChanged: (val) {
                      setState(() {
                        _hasHeader = val ?? true;
                      });
                    },
                  ),
                  const Text('Baris pertama adalah judul kolom (Header)', style: TextStyle(fontSize: 13)),
                ],
              ),
              
              const SizedBox(height: AppSpacing.space3),
              ElevatedButton(
                onPressed: _proceedToStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 2 VIEW: Column Mapping ---
  Widget _buildStep2View(List<CategoryModel> dbCategories, ThemeData theme) {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Langkah 2: Petakan Kolom Spreadsheet Anda',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.space2),
              const Text(
                'Sesuaikan kolom dari file Anda agar masuk ke dalam kolom database Pawcket. Kolom bertanda (*) wajib diisi.',
                style: TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              const SizedBox(height: AppSpacing.space4),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Date column picker
                      _buildColumnDropdown('Tanggal (Date) *', 'date'),
                      const SizedBox(height: AppSpacing.space3),

                      // Category column picker
                      _buildColumnDropdown('Kategori (Category) *', 'category'),
                      const SizedBox(height: AppSpacing.space3),

                      // Description column picker
                      _buildColumnDropdown('Keterangan / Deskripsi', 'description'),
                      const SizedBox(height: AppSpacing.space3),

                      // Vendor column picker
                      _buildColumnDropdown('Toko / Vendor (Opsional)', 'vendor'),
                      const SizedBox(height: AppSpacing.space3),

                      const Divider(),
                      const SizedBox(height: AppSpacing.space2),

                      // Explanation of amount mapping options
                      const Text(
                        'Metode Nominal: Anda bisa memilih kolom nominal tunggal (misal: "Nominal" / "Jumlah" dengan minus untuk pengeluaran), ATAU kolom Pemasukan & Pengeluaran terpisah.',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.neutral500),
                      ),
                      const SizedBox(height: AppSpacing.space3),

                      // Single Amount column picker
                      _buildColumnDropdown('Nominal Tunggal (Amount)', 'amount'),
                      const SizedBox(height: AppSpacing.space2),
                      const Center(child: Text('atau', style: TextStyle(fontSize: 12, color: AppColors.neutral500))),
                      const SizedBox(height: AppSpacing.space2),

                      // Separate Income/Expense column pickers
                      _buildColumnDropdown('Nominal Pemasukan Saja (Income)', 'income_amount'),
                      const SizedBox(height: AppSpacing.space3),
                      _buildColumnDropdown('Nominal Pengeluaran Saja (Expense)', 'expense_amount'),
                      const SizedBox(height: AppSpacing.space3),

                      // Type column picker (used with single amount)
                      _buildColumnDropdown('Tipe Transaksi (Type - Pemasukan/Pengeluaran)', 'type'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _proceedToStep3(dbCategories),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Tampilkan Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnDropdown(String label, String mappingKey) {
    return DropdownButtonFormField<int>(
      value: _columnMapping[mappingKey],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Tidak Dipetakan'),
        ),
        ...List.generate(_headers.length, (i) {
          return DropdownMenuItem<int>(
            value: i,
            child: Text(_headers[i]),
          );
        }),
      ],
      onChanged: (val) {
        setState(() {
          if (val == null) {
            _columnMapping.remove(mappingKey);
          } else {
            _columnMapping[mappingKey] = val;
          }
        });
      },
    );
  }

  // --- STEP 3 VIEW: Preview & Global Category Mapping ---
  Widget _buildStep3View(List<CategoryModel> dbCategories, ThemeData theme) {
    // Summarize amounts
    int totalIncome = 0;
    int totalExpense = 0;
    for (final row in _processedRows) {
      if (row.transactionType == 'income') {
        totalIncome += row.amount;
      } else {
        totalExpense += row.amount;
      }
    }

    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scrollable view containing all details and preview list
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Global Category Mapping Section
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                    color: AppColors.primary.withValues(alpha: 0.03),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pemetaan Kategori Spreadsheet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutral900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hubungkan kategori dari file Anda ke kategori resmi aplikasi Pawcket:',
                            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          
                          // List unique csv categories mapped to DB categories
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _categoryMappings.keys.length,
                            itemBuilder: (context, idx) {
                              final csvCatName = _categoryMappings.keys.elementAt(idx);
                              final selectedDbCat = _categoryMappings[csvCatName];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        csvCatName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.neutral500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 5,
                                      child: SizedBox(
                                        height: 40,
                                        child: DropdownButtonFormField<CategoryModel>(
                                          value: selectedDbCat,
                                          isDense: true,
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            border: OutlineInputBorder(),
                                          ),
                                          items: dbCategories.map((cat) {
                                            final color = CategoryModel.getColor(cat.colorHex);
                                            return DropdownMenuItem<CategoryModel>(
                                              value: cat,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    CategoryModel.getIconData(cat.iconName),
                                                    color: color,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(cat.categoryName, style: const TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _categoryMappings[csvCatName] = val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Total Summary Card
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Jumlah Baris', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
                              Text('${_processedRows.length}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Pemasukan', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
                              Text(
                                _formatCurrency(totalIncome),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Pengeluaran', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
                              Text(
                                _formatCurrency(totalExpense),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Title for Preview Section
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'Pratinjau Transaksi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neutral700),
                    ),
                  ),
                ),

                // 4. List Preview
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final row = _processedRows[index];
                      final isIncome = row.transactionType == 'income';
                      final dateStr = row.date != null 
                          ? '${row.date!.day}/${row.date!.month}/${row.date!.year}' 
                          : row.rawDate;
                      
                      // Get mapped category
                      final mappedDbCat = _categoryMappings[row.category.trim()] ?? 
                          _selectedFallbackCategory(isIncome);
                      final color = CategoryModel.getColor(mappedDbCat.colorHex);

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CategoryModel.getIconData(mappedDbCat.iconName),
                              color: color,
                              size: 16,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  row.description.isNotEmpty ? row.description : row.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'} ${_formatCurrency(row.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? AppColors.success : AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$dateStr • Kategori file: ${row.category}', style: const TextStyle(fontSize: 10)),
                              if (row.warning != null)
                                Tooltip(
                                  message: row.warning!,
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.warning),
                                      SizedBox(width: 2),
                                      Text('Peringatan', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _processedRows.length,
                  ),
                ),
              ],
            ),
          ),

          // Import Confirm buttons
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: ElevatedButton(
                  onPressed: _importData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Impor Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

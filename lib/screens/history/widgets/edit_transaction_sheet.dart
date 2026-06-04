import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/category.dart';
import '../../../models/dashboard_data.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/dashboard_provider.dart';

class EditTransactionSheet extends ConsumerStatefulWidget {
  final TransactionSummary transaction;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descController;
  late TextEditingController _vendorController;
  
  late String _transactionType; // 'expense' or 'income'
  int? _selectedCategoryId;
  late DateTime _selectedDate;
  String? _selectedPaymentMethod;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'Tunai'},
    {'value': 'debit_card', 'label': 'Kartu Debit'},
    {'value': 'e_wallet', 'label': 'E-Wallet'},
    {'value': 'bank_transfer', 'label': 'Transfer Bank'},
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction.amountIdr.toString());
    _descController = TextEditingController(text: widget.transaction.description);
    _selectedDate = widget.transaction.transactionDate;
    _transactionType = widget.transaction.transactionType;
    
    // We will initialize selectedCategoryId later once categories load or dynamically match it
    _selectedPaymentMethod = null;
    _vendorController = TextEditingController();
    
    _loadExtraDetails();
  }

  Future<void> _loadExtraDetails() async {
    // Fetch payment method and vendor from DB details since they're not in TransactionSummary
    final db = ref.read(historyProvider.notifier);
    final detailMap = await db.db.getTransactionWithCategory(widget.transaction.transactionId);
    if (detailMap != null && mounted) {
      setState(() {
        _selectedCategoryId = detailMap['category_id'] as int?;
        _selectedPaymentMethod = detailMap['payment_method'] as String?;
        _vendorController.text = detailMap['vendor_name'] as String? ?? '';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori')),
      );
      return;
    }

    final success = await ref.read(historyProvider.notifier).updateTransaction(
      transactionId: widget.transaction.transactionId,
      categoryId: _selectedCategoryId!,
      amountIdr: amount,
      description: _descController.text.trim(),
      date: _selectedDate,
      vendorName: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      transactionType: _transactionType,
    );

    if (success && mounted) {
      // Invalidate dashboard provider so dashboard metrics auto-refresh
      ref.invalidate(dashboardProvider);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil diperbarui')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui transaksi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
        top: AppSpacing.space4,
        left: AppSpacing.space4,
        right: AppSpacing.space4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Transaksi',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.space2),

              // Segmented Control for Type (Pemasukan / Pengeluaran)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pengeluaran')),
                      selected: _transactionType == 'expense',
                      selectedColor: AppColors.danger.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _transactionType == 'expense' ? AppColors.danger : AppColors.neutral700,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _transactionType = 'expense';
                            _selectedCategoryId = null; // Reset category since options change
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pemasukan')),
                      selected: _transactionType == 'income',
                      selectedColor: AppColors.success.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _transactionType == 'income' ? AppColors.success : AppColors.neutral700,
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _transactionType = 'income';
                            _selectedCategoryId = null; // Reset category since options change
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),

              // Description Input
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Keterangan tidak boleh kosong' : null,
              ),
              const SizedBox(height: AppSpacing.space3),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Nominal tidak boleh kosong';
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) return 'Nominal harus berupa angka positif';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space3),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Transaksi',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.neutral500),
                            ),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Category Picker
              categoriesAsync.when(
                data: (cats) {
                  // Filter categories based on transaction type
                  final isIncome = _transactionType == 'income';
                  final filteredCats = cats.where((c) => PredefinedCategory.isIncomeType(c.categoryType) == isIncome).toList();
                  
                  // Auto-select category if matching widget category exists
                  if (_selectedCategoryId == null && filteredCats.isNotEmpty) {
                    final matchingCat = filteredCats.firstWhere(
                      (c) => c.categoryName == widget.transaction.categoryName,
                      orElse: () => filteredCats.first,
                    );
                    _selectedCategoryId = matchingCat.categoryId;
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: filteredCats.map((cat) {
                      final color = CategoryModel.getColor(cat.colorHex);
                      return DropdownMenuItem<int>(
                        value: cat.categoryId,
                        child: Row(
                          children: [
                            Icon(
                              CategoryModel.getIconData(cat.iconName),
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(cat.categoryName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                    validator: (val) => val == null ? 'Silakan pilih kategori' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Gagal memuat kategori: $err', style: const TextStyle(color: AppColors.danger)),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran (Opsional)',
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Belum Dipilih'),
                  ),
                  ..._paymentMethods.map((pm) {
                    return DropdownMenuItem<String>(
                      value: pm['value'],
                      child: Text(pm['label']!),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedPaymentMethod = val;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.space3),

              // Vendor/Payee (Optional)
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(
                  labelText: 'Toko / Vendor / Penerima (Opsional)',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

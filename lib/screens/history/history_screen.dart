import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../models/dashboard_data.dart';
import '../../providers/category_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/edit_transaction_sheet.dart';
import 'csv_import_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadTransactions(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyProvider.notifier).loadTransactions(refresh: false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(historyProvider.notifier).setSearchQuery(query);
    });
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Hari Ini';
    if (checkDate == yesterday) return 'Kemarin';

    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDateRange() async {
    final state = ref.read(historyProvider);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
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

    if (picked != null) {
      ref.read(historyProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  void _showDeleteConfirmation(TransactionSummary tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini dapat dibatalkan dalam 5 detik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(historyProvider.notifier).deleteTransaction(tx);
              if (success && mounted) {
                // Invalidate dashboard provider so total sum updates
                ref.invalidate(dashboardProvider);
                _showUndoSnackBar();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation(int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus $count transaksi terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(historyProvider.notifier).deleteSelectedTransactions();
              if (success && mounted) {
                ref.invalidate(dashboardProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count transaksi berhasil dihapus')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUndoSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi berhasil dihapus'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Batal Hapus (Undo)',
          textColor: AppColors.primary,
          onPressed: () async {
            final success = await ref.read(historyProvider.notifier).undoDelete();
            if (success) {
              ref.invalidate(dashboardProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaksi berhasil dipulihkan')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showEditSheet(TransactionSummary tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditTransactionSheet(transaction: tx),
    ).then((updated) {
      if (updated == true) {
        // The provider automatically updates the list on save, no manually forced refresh needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final theme = Theme.of(context);

    // Group transactions by date
    final List<dynamic> listItems = [];
    DateTime? lastDate;
    for (final tx in state.transactions) {
      final txDate = DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day);
      if (lastDate == null || txDate != lastDate) {
        listItems.add(txDate); // Add date header node
        lastDate = txDate;
      }
      listItems.add(tx); // Add transaction node
    }

    final hasActiveFilters = state.searchQuery.isNotEmpty ||
        state.typeFilter != 'all' ||
        state.categoryFilter != null ||
        state.startDate != null;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: state.selectedTransactions.isNotEmpty
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.neutral900),
                onPressed: () => ref.read(historyProvider.notifier).clearSelection(),
              ),
              title: Text(
                '${state.selectedTransactions.length} Terpilih',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
              ),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all, color: AppColors.neutral900),
                  tooltip: 'Pilih Semua',
                  onPressed: () => ref.read(historyProvider.notifier).selectAll(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger),
                  tooltip: 'Hapus Terpilih',
                  onPressed: () => _showBulkDeleteConfirmation(state.selectedTransactions.length),
                ),
              ],
            )
          : AppBar(
              title: const Text(
                'Riwayat Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined, color: AppColors.primary),
                  tooltip: 'Impor Spreadsheet/CSV',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () => ref.read(historyProvider.notifier).loadTransactions(refresh: true),
                  tooltip: 'Segarkan',
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Panel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.neutral500),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.neutral500),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(historyProvider.notifier).setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.neutral0,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  
                  // Filter Row (Chips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Reset Filters Button
                        if (hasActiveFilters)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.filter_list_off, color: AppColors.danger),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(historyProvider.notifier).clearFilters();
                              },
                              tooltip: 'Reset Filter',
                              visualDensity: VisualDensity.compact,
                            ),
                          ),

                        // Type ChoiceChips
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: state.typeFilter == 'all',
                          onSelected: (sel) => ref.read(historyProvider.notifier).setTypeFilter('all'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected: state.typeFilter == 'expense',
                          onSelected: (sel) => ref.read(historyProvider.notifier).setTypeFilter('expense'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected: state.typeFilter == 'income',
                          onSelected: (sel) => ref.read(historyProvider.notifier).setTypeFilter('income'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        
                        // Category Dropdown Filter Chip
                        categoriesAsync.when(
                          data: (cats) {
                            final selectedCat = cats.firstWhere(
                              (c) => c.categoryId == state.categoryFilter,
                              orElse: () => CategoryModel(
                                userId: 0,
                                categoryName: 'Kategori',
                                categoryType: '',
                                isDefault: false,
                                createdAt: 0,
                                updatedAt: 0,
                              ),
                            );
                            
                            final hasCategory = state.categoryFilter != null;

                            return InputChip(
                              label: Text(hasCategory ? selectedCat.categoryName : 'Kategori'),
                              selected: hasCategory,
                              onSelected: (sel) {
                                _showCategoryPickerDialog(cats);
                              },
                              onDeleted: hasCategory 
                                  ? () => ref.read(historyProvider.notifier).setCategoryFilter(null)
                                  : null,
                              visualDensity: VisualDensity.compact,
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        const SizedBox(width: 8),

                        // Date Range Filter Chip
                        InputChip(
                          label: Text(
                            state.startDate != null && state.endDate != null
                                ? '${state.startDate!.day}/${state.startDate!.month} - ${state.endDate!.day}/${state.endDate!.month}'
                                : 'Rentang Tanggal',
                          ),
                          selected: state.startDate != null,
                          onSelected: (sel) => _selectDateRange(),
                          onDeleted: state.startDate != null
                              ? () => ref.read(historyProvider.notifier).setDateRange(null, null)
                              : null,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),

                        // Sort Order Chip
                        InputChip(
                          label: Text(state.sortBy == 'date_desc' ? 'Terbaru First' : 'Terlama First'),
                          onSelected: (sel) {
                            final nextSort = state.sortBy == 'date_desc' ? 'date_asc' : 'date_desc';
                            ref.read(historyProvider.notifier).setSortBy(nextSort);
                          },
                          avatar: Icon(
                            state.sortBy == 'date_desc' ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 14,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space2),

            // Logs List / Loading States
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(historyProvider.notifier).loadTransactions(refresh: true),
                child: state.isLoading && state.transactions.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.transactions.isEmpty
                        ? _buildEmptyState(hasActiveFilters)
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                            itemCount: listItems.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == listItems.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              final item = listItems[index];

                              // 1. Date Header Tile
                              if (item is DateTime) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                                  child: Text(
                                    _formatDateHeader(item),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.neutral500,
                                    ),
                                  ),
                                );
                              }

                              // 2. Transaction List Tile (Dismissible)
                              final tx = item as TransactionSummary;
                              final catColor = CategoryModel.getColor(tx.colorHex);
                              final isIncome = tx.transactionType == 'income';
                              final amountStr = tx.amountIdr.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]}.',
                                  );

                              final isSelected = state.selectedTransactions.contains(tx.transactionId);

                              return Dismissible(
                                key: Key('tx_${tx.transactionId}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  _showDeleteConfirmation(tx);
                                  return false; // Handled by dialog confirm button async
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                                  elevation: 0.5,
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.neutral0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isSelected ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
                                  ),
                                  child: ListTile(
                                    onLongPress: () => ref.read(historyProvider.notifier).toggleSelection(tx.transactionId),
                                    onTap: () {
                                      if (state.selectedTransactions.isNotEmpty) {
                                        ref.read(historyProvider.notifier).toggleSelection(tx.transactionId);
                                      } else {
                                        _showEditSheet(tx);
                                      }
                                    },
                                    leading: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(AppSpacing.space2),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CategoryModel.getIconData(tx.iconName),
                                            color: catColor,
                                            size: 20,
                                          ),
                                        ),
                                        
                                        // Sync status dot (Bottom right of category icon)
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: tx.isSyncedToCloud ? AppColors.success : AppColors.neutral500,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Text(
                                      tx.description.isNotEmpty ? tx.description : tx.categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      tx.categoryName,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    trailing: Text(
                                      '${isIncome ? '+' : '-'} Rp$amountStr',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isIncome ? AppColors.success : AppColors.danger,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😿', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                hasFilters 
                    ? 'Transaksi tidak ditemukan!' 
                    : 'Belum ada transaksi tercatat.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neutral900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters 
                    ? 'Cobalah ubah filter pencarian atau kategori Anda.' 
                    : 'Gunakan Mr. Oyen di tab Chat untuk mencatat, atau masukkan file data spreadsheet Anda untuk memuat riwayat.',
                style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!hasFilters)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                    );
                  },
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Impor Spreadsheet/CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerDialog(List<CategoryModel> cats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cats.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('Semua Kategori'),
                  onTap: () {
                    ref.read(historyProvider.notifier).setCategoryFilter(null);
                    Navigator.pop(ctx);
                  },
                );
              }
              
              final cat = cats[index - 1];
              final color = CategoryModel.getColor(cat.colorHex);
              
              return ListTile(
                leading: Icon(CategoryModel.getIconData(cat.iconName), color: color, size: 20),
                title: Text(cat.categoryName),
                onTap: () {
                  ref.read(historyProvider.notifier).setCategoryFilter(cat.categoryId);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

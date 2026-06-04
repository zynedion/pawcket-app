import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../services/database/local_db.dart';
import '../../widgets/common/mr_oyen_avatar.dart';
import '../chat/chat_screen.dart';
import '../history/history_screen.dart';
import '../../providers/dashboard_provider.dart';
import 'widgets/summary_cards.dart';
import 'widgets/expense_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const _DashboardTab(),
    const ChatScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.neutral500,
          backgroundColor: AppColors.neutral0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Mr. Oyen',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Tab 1: Dashboard (Original Category List layout)
// ---------------------------------------------------------
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  String _getMonthName(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _resetOnboarding(BuildContext context, WidgetRef ref) async {
    final db = LocalDb.instance;
    final user = await db.getUser();
    if (user != null) {
      final database = await db.database;
      await database.delete('chat_messages');
      await database.delete('chat_sessions');
      await database.delete('transactions');
      await database.delete('categories');
      await database.delete('user_preferences');
      await database.delete('users');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_id');

      ref.invalidate(onboardingProvider);
      ref.invalidate(categoryProvider);
      ref.invalidate(dashboardProvider);

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);

    final now = DateTime.now();
    final isCurrentMonth = dashboardState.selectedMonth.year == now.year &&
        dashboardState.selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text(
          'Pawcket Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Reset Onboarding (Test Mode)',
            onPressed: () => _resetOnboarding(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.loadDashboard(),
          child: dashboardState.isLoading && dashboardState.recentTransactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month navigation selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                            onPressed: () => notifier.changeMonth(-1),
                          ),
                          Text(
                            _getMonthName(dashboardState.selectedMonth),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                            onPressed: isCurrentMonth ? null : () => notifier.changeMonth(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),

                      // Summary cards
                      SummaryCards(
                        totalIncome: dashboardState.totalIncome,
                        totalExpense: dashboardState.totalExpense,
                        totalTransactions: dashboardState.totalTransactions,
                        cumulativeBalance: dashboardState.cumulativeBalance,
                      ),
                      const SizedBox(height: AppSpacing.space3),

                      if (dashboardState.recentTransactions.isEmpty) ...[
                        _buildEmptyState(context),
                      ] else ...[
                        // Pie chart breakdown
                        if (dashboardState.totalExpense > 0)
                          ExpenseChart(
                            breakdowns: dashboardState.categoryBreakdown,
                            totalExpense: dashboardState.totalExpense,
                          ),
                        const SizedBox(height: AppSpacing.space4),

                        Text(
                          'Transaksi Bulan Ini',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.space2),

                        // List of recent transactions for month
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dashboardState.recentTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = dashboardState.recentTransactions[index];
                            final color = CategoryModel.getColor(tx.colorHex);
                            final isIncome = tx.transactionType == 'income';
                            final amountStr = tx.amountIdr.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]}.',
                            );
                            final formattedAmount = '${isIncome ? '+' : '-'} Rp$amountStr';

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(AppSpacing.space2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CategoryModel.getIconData(tx.iconName),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  tx.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
                                ),
                                subtitle: Text(
                                  '${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                trailing: Text(
                                  formattedAmount,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncome ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Load More Button
                        if (notifier.hasMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: TextButton(
                                onPressed: () => notifier.loadMore(),
                                child: const Text('Load More'),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.space6),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MrOyenAvatar(size: 100, expression: 'mischievous'),
            const SizedBox(height: AppSpacing.space4),
            const Text(
              'Tidak ada transaksi bulan ini! 😸',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Kamu belum mencatat pengeluaran di bulan ini. Ketuk tombol di bawah untuk mencatat transaksi pertamamu!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geser ke tab Mr. Oyen untuk mencatat pengeluaran!')),
                );
              },
              child: const Text('Mulai Catat'),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 3 placeholder removed. New HistoryScreen linked directly.

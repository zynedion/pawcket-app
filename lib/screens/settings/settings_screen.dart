import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/mr_oyen_avatar.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _maskDeviceId(String? deviceId) {
    if (deviceId == null) return 'Memuat...';
    if (deviceId.length <= 8) return deviceId;
    return 'xxxxx${deviceId.substring(deviceId.length - 8)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Memuat...';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatLastSync(DateTime? date) {
    if (date == null) return 'Belum pernah disinkronkan';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Show error banner if any
    if (state.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(settingsProvider.notifier).loadSettings(); // Retry/reset error state
      });
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile card
                  _buildProfileCard(context, state),
                  const SizedBox(height: AppSpacing.space4),

                  // 2. Preferences
                  _buildSectionHeader('Preferensi'),
                  _buildPreferenceCard(context, state, notifier),
                  const SizedBox(height: AppSpacing.space4),

                  // 3. Info & About
                  _buildSectionHeader('Informasi & Bantuan'),
                  _buildInfoCard(context, state, notifier),
                  const SizedBox(height: AppSpacing.space4),

                  // 4. Danger Zone
                  _buildSectionHeader('Tindakan Berbahaya'),
                  _buildDangerZoneCard(context, notifier),
                  const SizedBox(height: AppSpacing.space8),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.neutral500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            const MrOyenAvatar(size: 72, expression: 'smirk'),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mr. Oyen\'s Roommate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      if (state.deviceId != null) {
                        Clipboard.setData(ClipboardData(text: state.deviceId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID Perangkat disalin ke clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Device ID: ${_maskDeviceId(state.deviceId)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 12, color: AppColors.neutral500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Akun dibuat: ${_formatDate(state.userCreatedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(BuildContext context, SettingsState state, SettingsNotifier notifier) {
    final prefs = state.preferences;
    final enableVoice = prefs?.enableVoiceInput ?? true;
    final enableCloud = prefs?.enableCloudSync ?? false;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Input Suara (Dikte)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Tampilkan tombol mikrofon untuk pencatatan berbasis suara.'),
            value: enableVoice,
            onChanged: (val) {
              notifier.updateVoiceInput(val);
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.neutral100),
          SwitchListTile(
            title: const Text('Backup Awan (Beta)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Sinkronkan transaksi Anda ke penyimpanan awan.'),
            value: enableCloud,
            onChanged: (val) {
              if (val) {
                _showCloudSyncConfirmation(context, notifier);
              } else {
                notifier.updateCloudSync(false);
              }
            },
          ),
          if (enableCloud) ...[
            const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.neutral100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Sinkronisasi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.neutral900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatLastSync(state.lastSyncTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      state.isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : TextButton(
                              onPressed: () async {
                                await notifier.syncNow();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sinkronisasi selesai!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                'Sinkronkan Sekarang',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pencadangan saat ini disimulasikan secara lokal (Beta).',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SettingsState state, SettingsNotifier notifier) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primary),
            title: const Text('Tentang Pawcket', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.neutral500),
            onTap: () => _showAboutSheet(context, state),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.neutral100),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: AppColors.secondary),
            title: const Text('Hubungi Dukungan / Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('support@pawcket.app'),
            trailing: const Icon(Icons.copy, size: 16, color: AppColors.neutral500),
            onTap: () {
              Clipboard.setData(ClipboardData(text: 'support@pawcket.app'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email support disalin ke clipboard!')),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.neutral100),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Versi Aplikasi', style: TextStyle(color: AppColors.neutral500, fontSize: 13)),
                Text(
                  '${state.appVersion ?? '1.0.0'} (${state.buildNumber ?? '1'})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutral900, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard(BuildContext context, SettingsNotifier notifier) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.danger),
            title: const Text('Hapus Riwayat Chat', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
            subtitle: const Text('Hapus semua obrolan dengan Mr. Oyen.'),
            onTap: () => _showClearChatConfirmation(context, notifier),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.neutral100),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('Hapus Semua Data / Reset App', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger)),
            subtitle: const Text('Hapus semua transaksi, kategori, dan reset ke onboarding.'),
            onTap: () => _showResetAppConfirmation(context, notifier),
          ),
        ],
      ),
    );
  }

  void _showCloudSyncConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Backup Awan (Beta)?'),
        content: const Text(
          'Backup awan akan menyinkronkan transaksi finansial Anda ke server kami yang aman.\n\nCatatan: Fitur pencadangan saat ini sedang dalam versi Beta. Anda dapat menonaktifkan pencadangan kapan saja untuk menjaga data Anda tetap lokal sepenuhnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.updateCloudSync(true);
              Navigator.of(context).pop();
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  void _showClearChatConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat?'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat obrolan dengan Mr. Oyen? Tindakan ini tidak akan menghapus transaksi finansial Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.clearChatHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat chat berhasil dibersihkan!')),
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

  void _showResetAppConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data & Reset?', style: TextStyle(color: AppColors.danger)),
        content: const Text('Apakah Anda yakin ingin mereset aplikasi? Tindakan ini akan menghapus semua transaksi, kategori buatan Anda, riwayat chat, dan pengaturan. Ini TIDAK BISA dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.neutral500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showResetAppDoubleConfirmation(context, notifier);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResetAppDoubleConfirmation(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KONFIRMASI AKHIR!', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
        content: const Text('Tindakan ini sepenuhnya merusak dan menghapus semua catatan keuangan Anda. Ketuk tombol di bawah untuk menghapus seluruh data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('BATALKAN', style: TextStyle(color: AppColors.neutral500, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await notifier.resetAppData(context);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('HAPUS SEMUA DATA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context, SettingsState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const MrOyenAvatar(size: 110, expression: 'happy'),
                  const SizedBox(height: 16),
                  const Text(
                    'Meet Mr. Oyen 🐱',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your sassy orange cat financial companion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pawcket dirancang khusus untuk Gen Z agar pencatatan keuangan tidak lagi membosankan. Melalui interaksi percakapan natural dengan Mr. Oyen, Anda bisa memantau keuangan tanpa pusing.\n\nMr. Oyen akan memuji kebiasaan hemat Anda, tetapi bersiaplah untuk diomeli habis-habisan saat Anda mulai boros!',
                    style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.neutral700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.neutral100),
                  const SizedBox(height: 16),
                  const Text(
                    'Dibuat dengan ❤️ untuk generasi hemat pintar.',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral500, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi ${state.appVersion ?? '1.0.0'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

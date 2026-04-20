import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('about.termsOfService')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _buildLastUpdated(context),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: '1. Penerimaan Syarat',
            body:
                'Dengan mengunduh, memasang, atau menggunakan aplikasi Cuan Flow, '
                'Anda menyetujui untuk terikat oleh Syarat & Ketentuan ini. '
                'Jika Anda tidak menyetujui syarat ini, mohon untuk tidak menggunakan aplikasi.',
          ),
          _buildSection(
            context,
            title: '2. Deskripsi Layanan',
            body:
                'Cuan Flow adalah aplikasi pencatatan keuangan yang dirancang untuk membantu UMKM Indonesia '
                'dalam mengelola pemasukan dan pengeluaran. '
                'Aplikasi ini bukan merupakan layanan perbankan, investasi, atau keuangan profesional.',
          ),
          _buildSection(
            context,
            title: '3. Akun Pengguna',
            body:
                'Anda bertanggung jawab untuk:\n'
                '• Menjaga kerahasiaan PIN dan kredensial akun Anda\n'
                '• Semua aktivitas yang terjadi di bawah akun Anda\n'
                '• Memberikan informasi yang akurat saat pendaftaran\n\n'
                'Kami berhak menangguhkan akun yang melanggar ketentuan ini.',
          ),
          _buildSection(
            context,
            title: '4. Penggunaan yang Diperbolehkan',
            body:
                'Anda boleh menggunakan Cuan Flow hanya untuk tujuan yang sah, yaitu:\n'
                '• Mencatat transaksi keuangan bisnis atau pribadi\n'
                '• Mengelola outlet dan produk usaha Anda\n'
                '• Membuat laporan keuangan untuk keperluan internal',
          ),
          _buildSection(
            context,
            title: '5. Larangan Penggunaan',
            body:
                'Anda dilarang:\n'
                '• Menggunakan aplikasi untuk aktivitas ilegal\n'
                '• Mencoba meretas atau mengganggu sistem kami\n'
                '• Menyalin, mendistribusikan, atau memodifikasi aplikasi\n'
                '• Menggunakan aplikasi untuk menyimpan data orang lain tanpa izin mereka',
          ),
          _buildSection(
            context,
            title: '6. Data dan Privasi',
            body:
                'Penggunaan data Anda diatur oleh Kebijakan Privasi kami yang merupakan '
                'bagian tidak terpisahkan dari Syarat & Ketentuan ini. '
                'Anda adalah pemilik sah dari seluruh data keuangan yang Anda masukkan ke dalam aplikasi.',
          ),
          _buildSection(
            context,
            title: '7. Batasan Tanggung Jawab',
            body:
                'Cuan Flow disediakan "sebagaimana adanya". Kami tidak bertanggung jawab atas:\n'
                '• Kehilangan data akibat kerusakan perangkat\n'
                '• Keputusan keuangan yang dibuat berdasarkan data di aplikasi\n'
                '• Gangguan layanan di luar kendali kami\n\n'
                'Kami sangat menyarankan untuk melakukan backup data secara berkala.',
          ),
          _buildSection(
            context,
            title: '8. Perubahan Layanan',
            body:
                'Kami berhak mengubah, menangguhkan, atau menghentikan layanan kapan saja. '
                'Perubahan pada Syarat & Ketentuan akan diinformasikan melalui notifikasi aplikasi '
                'atau email yang terdaftar.',
          ),
          _buildSection(
            context,
            title: '9. Hukum yang Berlaku',
            body:
                'Syarat & Ketentuan ini diatur oleh hukum Republik Indonesia. '
                'Setiap sengketa akan diselesaikan melalui jalur mediasi atau pengadilan '
                'yang berwenang di Indonesia.',
          ),
          _buildSection(
            context,
            title: '10. Hubungi Kami',
            body:
                'Untuk pertanyaan mengenai Syarat & Ketentuan ini, hubungi:\n\n'
                'Email: support@cuanflow.app',
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return Text(
      'Terakhir diperbarui: 1 Januari 2025',
      style: TextStyle(
        fontSize: 12,
        color: context.appColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

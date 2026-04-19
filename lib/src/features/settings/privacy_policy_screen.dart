import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kebijakan Privasi'),
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
            title: '1. Informasi yang Kami Kumpulkan',
            body:
                'Kami mengumpulkan informasi yang Anda berikan secara langsung, '
                'seperti nama, alamat email, dan data transaksi keuangan yang Anda masukkan ke dalam aplikasi. '
                'Kami tidak mengumpulkan informasi sensitif seperti nomor rekening bank atau kartu kredit.',
          ),
          _buildSection(
            context,
            title: '2. Cara Kami Menggunakan Informasi',
            body:
                'Informasi yang dikumpulkan digunakan untuk:\n'
                '• Menyediakan dan meningkatkan layanan aplikasi\n'
                '• Menyinkronkan data antar perangkat melalui Supabase\n'
                '• Mengirim notifikasi yang relevan dengan aktivitas keuangan Anda\n'
                '• Menampilkan iklan yang relevan melalui Google AdMob',
          ),
          _buildSection(
            context,
            title: '3. Penyimpanan Data',
            body:
                'Data Anda disimpan secara aman di server Supabase. '
                'Kami menerapkan enkripsi dan kebijakan keamanan row-level untuk melindungi data Anda. '
                'Data lokal pada perangkat Anda dikelola sepenuhnya oleh Anda.',
          ),
          _buildSection(
            context,
            title: '4. Berbagi Data dengan Pihak Ketiga',
            body:
                'Kami tidak menjual atau menyewakan data pribadi Anda kepada pihak ketiga. '
                'Data dapat dibagikan hanya kepada:\n'
                '• Supabase (penyimpanan cloud)\n'
                '• Google AdMob (layanan iklan)\n'
                '• Pihak berwenang jika diwajibkan oleh hukum yang berlaku',
          ),
          _buildSection(
            context,
            title: '5. Hak Pengguna',
            body:
                'Anda berhak untuk:\n'
                '• Mengakses data pribadi Anda\n'
                '• Meminta koreksi data yang tidak akurat\n'
                '• Menghapus akun dan seluruh data Anda\n'
                '• Menolak pemrosesan data untuk tujuan pemasaran\n\n'
                'Untuk mengajukan permintaan, hubungi kami di support@cuanflow.app',
          ),
          _buildSection(
            context,
            title: '6. Keamanan',
            body:
                'Kami menggunakan langkah-langkah keamanan standar industri untuk melindungi informasi Anda. '
                'Namun, tidak ada metode transmisi data melalui internet yang 100% aman. '
                'Kami mendorong Anda untuk menggunakan PIN yang kuat.',
          ),
          _buildSection(
            context,
            title: '7. Perubahan Kebijakan',
            body:
                'Kami dapat memperbarui Kebijakan Privasi ini sewaktu-waktu. '
                'Perubahan signifikan akan diberitahukan melalui notifikasi dalam aplikasi. '
                'Penggunaan berkelanjutan setelah perubahan berarti Anda menyetujui kebijakan yang diperbarui.',
          ),
          _buildSection(
            context,
            title: '8. Hubungi Kami',
            body:
                'Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, '
                'hubungi kami di:\n\nEmail: support@cuanflow.app',
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

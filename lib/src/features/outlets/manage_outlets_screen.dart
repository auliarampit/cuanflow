import 'package:flutter/material.dart';

import '../../core/models/outlet_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class ManageOutletsScreen extends StatelessWidget {
  const ManageOutletsScreen({super.key});

  void _showOutletForm(
    BuildContext context, {
    OutletModel? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _OutletFormSheet(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, OutletModel outlet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Outlet'),
        content: Text('Yakin hapus outlet "${outlet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.appState.deleteOutlet(outlet.id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outlets = context.appState.outlets;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Kelola Outlet'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showOutletForm(context),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Outlet',
          ),
        ],
      ),
      body: outlets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada outlet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showOutletForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Outlet'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: outlets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final outlet = outlets[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  outlet.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (outlet.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandBlue
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.brandBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (outlet.address != null &&
                                outlet.address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                outlet.address!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showOutletForm(context, existing: outlet),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.brandBlue,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, outlet),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.negative,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _OutletFormSheet extends StatefulWidget {
  const _OutletFormSheet({this.existing});

  final OutletModel? existing;

  @override
  State<_OutletFormSheet> createState() => _OutletFormSheetState();
}

class _OutletFormSheetState extends State<_OutletFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existing?.name ?? '');
    _addressController =
        TextEditingController(text: widget.existing?.address ?? '');
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama outlet tidak boleh kosong'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    final appState = context.appState;
    if (widget.existing != null) {
      appState.updateOutlet(
        widget.existing!.copyWith(
          name: name,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          isDefault: _isDefault,
        ),
      );
    } else {
      appState.addOutlet(
        name: name,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit Outlet' : 'Tambah Outlet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nama Outlet',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.storefront_outlined),
              hintText: 'contoh: Outlet Pusat, Cabang Mall A',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          const Text(
            'Alamat (opsional)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined),
              hintText: 'contoh: Jl. Sudirman No. 10',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          if (isEdit) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Jadikan outlet default'),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _save(context),
              child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Outlet'),
            ),
          ),
        ],
      ),
    );
  }
}

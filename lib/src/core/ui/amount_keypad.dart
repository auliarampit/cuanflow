import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatters/idr_formatter.dart';
import '../theme/app_dynamic_colors.dart';

/// Tampilkan keypad angka ala kalkulator (1-9, 0, 00, 000, hapus, Selesai).
///
/// Mengembalikan nominal (int) saat user menekan "Selesai", atau `null`
/// jika sheet ditutup tanpa konfirmasi. Dipakai menggantikan keyboard OS
/// untuk field jumlah uang supaya input cepat dan bisa selalu di-dismiss.
Future<int?> showAmountKeypad(
  BuildContext context, {
  required int initialValue,
  required Color accentColor,
  String? title,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AmountKeypadSheet(
      initialValue: initialValue,
      accentColor: accentColor,
      title: title,
    ),
  );
}

class _AmountKeypadSheet extends StatefulWidget {
  const _AmountKeypadSheet({
    required this.initialValue,
    required this.accentColor,
    this.title,
  });

  final int initialValue;
  final Color accentColor;
  final String? title;

  @override
  State<_AmountKeypadSheet> createState() => _AmountKeypadSheetState();
}

class _AmountKeypadSheetState extends State<_AmountKeypadSheet> {
  // Simpan sebagai string digit mentah, mis. "350000".
  late String _digits;

  @override
  void initState() {
    super.initState();
    _digits = widget.initialValue > 0 ? widget.initialValue.toString() : '';
  }

  int get _value => int.tryParse(_digits) ?? 0;

  void _append(String d) {
    // Jangan mulai dengan nol (00 / 000 / 0 saat masih kosong → tetap 0).
    if (_digits.isEmpty && (d == '0' || d == '00' || d == '000')) return;
    // Batasi maksimal 12 digit (~ratusan miliar) biar tidak overflow tampilan.
    if (_digits.length + d.length > 12) return;
    setState(() => _digits += d);
    HapticFeedback.selectionClick();
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
    HapticFeedback.selectionClick();
  }

  void _clear() {
    if (_digits.isEmpty) return;
    setState(() => _digits = '');
    HapticFeedback.mediumImpact();
  }

  void _done() => Navigator.of(context).pop(_value);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = widget.accentColor;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grip
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Tampilan nominal
            Row(
              children: [
                if (widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      IdrFormatter.format(_value),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: _digits.isEmpty
                            ? colors.textSecondary.withValues(alpha: 0.4)
                            : accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: colors.outline),
            const SizedBox(height: 10),

            // Grid angka
            _row(['1', '2', '3']),
            _row(['4', '5', '6']),
            _row(['7', '8', '9']),
            _row(['00', '0', '000']),
            const SizedBox(height: 10),

            // Aksi: Hapus + Selesai
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onLongPress: _clear,
                    child: OutlinedButton.icon(
                      onPressed: _backspace,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        side: BorderSide(color: colors.outline),
                        foregroundColor: colors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.backspace_outlined, size: 20),
                      label: const Text('Hapus'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _done,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _KeyButton(label: keys[i], onTap: () => _append(keys[i]))),
          ],
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.cardSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

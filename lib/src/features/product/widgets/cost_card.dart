import 'package:flutter/material.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/models/product_model.dart';

class CostCard extends StatelessWidget {
  const CostCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final ProductCost item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Determine icon based on name (simple heuristic)
    IconData iconData = Icons.monetization_on;
    Color iconColor = Colors.orange;
    
    final lowerName = item.name.toLowerCase();
    if (lowerName.contains('gas') || lowerName.contains('bakar')) {
      iconData = Icons.gas_meter;
      iconColor = Colors.orange;
    } else if (lowerName.contains('listrik') || lowerName.contains('air')) {
      iconData = Icons.electric_bolt;
      iconColor = Colors.yellow;
    } else if (lowerName.contains('kemasan') || lowerName.contains('pack')) {
      iconData = Icons.inventory_2;
      iconColor = Colors.blue;
    } else if (lowerName.contains('gaji') || lowerName.contains('karyawan')) {
      iconData = Icons.people;
      iconColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16262E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  IdrFormatter.format(item.cost.round()).replaceAll('Rp ', ''),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertReportSheet extends StatelessWidget {
  final Function(AlertType type) onAlertSelected;

  const AlertReportSheet({super.key, required this.onAlertSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Signaler un événement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildAlertButton(
                context,
                type: AlertType.police,
                label: 'Police / Contrôle',
                emoji: '👮',
                color: const Color(0xFF3B82F6),
              ),
              _buildAlertButton(
                context,
                type: AlertType.accident,
                label: 'Accident',
                emoji: '💥',
                color: const Color(0xFFEF4444),
              ),
              _buildAlertButton(
                context,
                type: AlertType.hazard,
                label: 'Danger sur la voie',
                emoji: '⚠️',
                color: const Color(0xFFF59E0B),
              ),
              _buildAlertButton(
                context,
                type: AlertType.traffic,
                label: 'Bouchon',
                emoji: '🚗',
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAlertButton(
    BuildContext context, {
    required AlertType type,
    required String label,
    required String emoji,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onAlertSelected(type);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

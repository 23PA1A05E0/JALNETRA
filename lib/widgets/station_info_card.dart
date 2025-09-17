import 'package:flutter/material.dart';
import '../models/dwlr_station.dart';

/// Station info card widget
class StationInfoCard extends StatelessWidget {
  final DWLRStation station;

  const StationInfoCard({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Station Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Station ID', station.stationId),
            _buildInfoRow('Location', '${station.district}, ${station.state}'),
            _buildInfoRow('Basin', station.basin),
            _buildInfoRow('Aquifer Type', station.aquiferType),
            _buildInfoRow('Total Depth', '${station.depth.toStringAsFixed(1)} m'),
            _buildInfoRow('Coordinates', '${station.latitude.toStringAsFixed(4)}, ${station.longitude.toStringAsFixed(4)}'),
            if (station.remarks != null && station.remarks!.isNotEmpty)
              _buildInfoRow('Remarks', station.remarks!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

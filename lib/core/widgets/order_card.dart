import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String title;
  final String detail;
  final String status;
  final Color color;
  final double progress;

  const OrderCard({
    super.key,
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
    this.progress = 0.68,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: const Color(0xff1f7a4d),
              backgroundColor: const Color(0xffe0e0e0),
            ),
          ],
        ),
      ),
    );
  }
}

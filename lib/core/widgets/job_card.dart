import 'package:flutter/material.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String route;
  final String detail;
  final String fee;
  final bool accepted;
  final VoidCallback? onAccept;

  const JobCard({
    super.key,
    required this.title,
    required this.route,
    required this.detail,
    required this.fee,
    this.accepted = false,
    this.onAccept,
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
                const Icon(
                  Icons.route_rounded,
                  color: Color(0xff1f7a4d),
                ),
                const SizedBox(width: 8),
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
                  fee,
                  style: const TextStyle(
                    color: Color(0xff1f7a4d),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              route,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              detail,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: accepted ? null : onAccept,
                style: accepted
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                      )
                    : null,
                child: Text(accepted ? 'Job Accepted' : 'Accept job'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alias for backward compatibility
class Job extends StatelessWidget {
  final String t, r, d, f;
  final VoidCallback? onAccept;

  const Job(this.t, this.r, this.d, this.f, {super.key, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return JobCard(
      title: t,
      route: r,
      detail: d,
      fee: f,
      onAccept: onAccept,
    );
  }
}

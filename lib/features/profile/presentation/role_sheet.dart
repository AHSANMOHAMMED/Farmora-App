import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';

class RoleSheet extends StatelessWidget {
  const RoleSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Switch preview role',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...Role.values.map(
            (r) => ListTile(
              leading: Icon(r.icon, color: const Color(0xff1f7a4d)),
              title: Text(r.label),
              onTap: () {
                context.read<FarmoraState>().setRole(r);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

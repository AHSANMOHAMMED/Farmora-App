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
            'Account role',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final state = context.watch<FarmoraState>();
              final currentRole = state.role;
              return Column(
                children: Role.values.map((r) {
                  final isSelected = r == currentRole;
                  return ListTile(
                    leading: Icon(r.icon,
                        color: isSelected
                            ? const Color(0xff1f7a4d)
                            : Colors.grey.shade600),
                    title: Text(
                      r.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xff1f7a4d) : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Color(0xff1f7a4d))
                        : null,
                    onTap: () {
                      state.setRole(r);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${r.label} view'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

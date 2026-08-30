import 'package:flutter/material.dart';

enum Role { farmer, buyer, transporter, admin }

extension RoleInfo on Role {
  String get label {
    switch (this) {
      case Role.farmer:
        return 'Farmer';
      case Role.buyer:
        return 'Buyer';
      case Role.transporter:
        return 'Transport provider';
      case Role.admin:
        return 'System Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case Role.farmer:
        return Icons.agriculture_rounded;
      case Role.buyer:
        return Icons.shopping_basket_rounded;
      case Role.transporter:
        return Icons.local_shipping_rounded;
      case Role.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String get description {
    switch (this) {
      case Role.farmer:
        return 'Sell your harvest with confidence.';
      case Role.buyer:
        return 'Fresh produce, straight to you.';
      case Role.transporter:
        return 'Earn while you serve your community.';
      case Role.admin:
        return 'Manage the Farmora ecosystem.';
    }
  }
}

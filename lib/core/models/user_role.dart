import 'package:flutter/material.dart';

enum Role { farmer, buyer, transporter }

extension RoleInfo on Role {
  String get label {
    switch (this) {
      case Role.farmer:
        return 'Farmer';
      case Role.buyer:
        return 'Buyer';
      case Role.transporter:
        return 'Transport provider';
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
    }
  }
}

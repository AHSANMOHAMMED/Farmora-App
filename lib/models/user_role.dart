import 'package:flutter/material.dart';

import '../core/localization/l10n.dart';

enum Role { farmer, buyer, transporter, admin }

extension RoleInfo on Role {
  /// Display name in the current app language. Firestore stores [name].
  String get label => switch (this) {
        Role.farmer => L10n.current.roleFarmer,
        Role.buyer => L10n.current.roleBuyer,
        Role.transporter => L10n.current.roleTransporter,
        Role.admin => L10n.current.roleAdmin,
      };

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

  String get description => switch (this) {
        Role.farmer => L10n.current.roleFarmerDescription,
        Role.buyer => L10n.current.roleBuyerDescription,
        Role.transporter => L10n.current.roleTransporterDescription,
        Role.admin => L10n.current.roleAdminDescription,
      };
}

import 'package:flutter/material.dart';

import '../core/localization/l10n.dart';

enum Role {
  farmer,
  buyer,
  transporter,
  admin,
  supplier,
  expert,
  driver,
  warehouse,
  inspector,
  finance,
}

/// Roles people pick at signup. Admin and finance accounts are assigned by
/// an admin.
const kSelfSignupRoles = [
  Role.farmer,
  Role.buyer,
  Role.transporter,
  Role.driver,
  Role.supplier,
  Role.warehouse,
  Role.inspector,
  Role.expert,
];

extension RoleInfo on Role {
  /// Display name in the current app language. Firestore stores [name].
  String get label => switch (this) {
        Role.farmer => L10n.current.roleFarmer,
        Role.buyer => L10n.current.roleBuyer,
        Role.transporter => L10n.current.roleTransporter,
        Role.admin => L10n.current.roleAdmin,
        Role.supplier => L10n.current.roleSupplier,
        Role.expert => L10n.current.roleExpert,
        Role.driver => L10n.current.roleDriver,
        Role.warehouse => L10n.current.roleWarehouse,
        Role.inspector => L10n.current.roleInspector,
        Role.finance => L10n.current.roleFinance,
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
      case Role.supplier:
        return Icons.storefront_rounded;
      case Role.expert:
        return Icons.school_rounded;
      case Role.driver:
        return Icons.drive_eta_rounded;
      case Role.warehouse:
        return Icons.warehouse_rounded;
      case Role.inspector:
        return Icons.fact_check_rounded;
      case Role.finance:
        return Icons.account_balance_rounded;
    }
  }

  String get description => switch (this) {
        Role.farmer => L10n.current.roleFarmerDescription,
        Role.buyer => L10n.current.roleBuyerDescription,
        Role.transporter => L10n.current.roleTransporterDescription,
        Role.admin => L10n.current.roleAdminDescription,
        Role.supplier => L10n.current.roleSupplierDescription,
        Role.expert => L10n.current.roleExpertDescription,
        Role.driver => L10n.current.roleDriverDescription,
        Role.warehouse => L10n.current.roleWarehouseDescription,
        Role.inspector => L10n.current.roleInspectorDescription,
        Role.finance => L10n.current.roleFinanceDescription,
      };
}

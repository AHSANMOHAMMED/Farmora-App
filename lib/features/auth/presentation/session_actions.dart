import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../providers/farmora_state.dart';
import '../../transporter/application/transporter_controller.dart';
import 'auth_gate.dart';

/// Stops the transporter module's live subscriptions, when that provider is
/// in the tree (it is provided app-wide in app.dart; tests may omit it).
void unbindTransporterController(BuildContext context) {
  try {
    Provider.of<TransporterController>(context, listen: false).unbind();
  } on ProviderNotFoundException {
    // Not provided in this tree — nothing to unbind.
  }
}

/// Signs out everywhere (FarmoraState + transporter module) and returns to a
/// fresh [AuthGate] from the root navigator. Throws when sign-out fails.
Future<void> signOutAndReset(BuildContext context, {String? reason}) async {
  final state = context.read<FarmoraState>();
  unbindTransporterController(context);
  await state.signOut(reason: reason);
  if (context.mounted) AuthGate.resetTo(context);
}

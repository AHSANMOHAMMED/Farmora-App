import 'package:flutter/material.dart';

import '../../../../core/localization/app_format.dart';
import '../../../../models/transport_job.dart';
import '../../../../services/delivery_location_service.dart';
import '../../domain/collection_job.dart';

/// Backend (`transport_jobs.status`) value for a [CollectionJobStatus].
String transportStatusFor(CollectionJobStatus status) => switch (status) {
      CollectionJobStatus.open => 'requested',
      CollectionJobStatus.accepted => 'accepted',
      CollectionJobStatus.collected => 'pickedUp',
      CollectionJobStatus.inTransit => 'inTransit',
      CollectionJobStatus.completed => 'delivered',
      CollectionJobStatus.cancelled => 'cancelled',
    };

/// Builds the [TransportJob] view used by the active-delivery screen from a
/// transporter-module [CollectionJob]. The screen then follows the live
/// Firestore document for location and status updates.
TransportJob transportJobFrom(CollectionJob job) => TransportJob(
      id: job.id,
      title: job.produceName,
      route: '${job.pickupLocation} → ${job.deliveryLocation}',
      detail: job.notes ?? '',
      fee: job.deliveryFeeMinor == null
          ? ''
          : AppFormat.lkr(job.deliveryFeeMinor! / 100),
      accepted: job.status != CollectionJobStatus.open,
      status: transportStatusFor(job.status),
      orderId: job.orderId,
      transporterId: job.logisticsProviderId,
      pickup: job.pickupLocation,
      dropoff: job.deliveryLocation,
      buyerId: job.buyerId.isEmpty ? null : job.buyerId,
      farmerId: job.farmerId.isEmpty ? null : job.farmerId,
      updatedAt: job.updatedAt,
      deliveryFeeMinor: job.deliveryFeeMinor,
      quantityValue: job.quantity,
      unit: job.unit,
      productName: job.produceName,
      farmerName: job.farmerName,
      buyerName: job.buyerName,
      createdAt: job.createdAt,
    );

/// Keeps live location sharing in step with a successful status change:
/// pickup / in-transit start sharing (with the user's permission consent),
/// delivered / cancelled stop it. Never throws; when sharing could not be
/// started a hint is shown so the transporter can retry from the
/// active-delivery screen.
Future<void> syncLiveSharing(
  BuildContext context,
  String jobId,
  CollectionJobStatus status,
) async {
  final service = DeliveryLocationService.instance;
  if (status == CollectionJobStatus.completed ||
      status == CollectionJobStatus.cancelled) {
    service.onJobStatusChanged(jobId, transportStatusFor(status));
    return;
  }
  if (status != CollectionJobStatus.collected &&
      status != CollectionJobStatus.inTransit) {
    return;
  }
  var started = false;
  try {
    started = await service.requestConsentAndStart(jobId: jobId);
  } catch (_) {
    started = false;
  }
  if (started || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        'Live location is not being shared. Allow location access and '
        'start sharing from Active delivery.',
      ),
    ),
  );
}

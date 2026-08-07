import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';

/// Enables local sample content while developing the order feed. Release
/// builds always show the actual backend result, including the empty state.
final showOrderPreviewProvider = Provider<bool>((ref) => kDebugMode);

/// Returns static preview data only for an empty history response in a debug
/// build. These never become an active order and cannot change server state.
List<RiderOrderModel> orderPreviewsFor(OrderHistoryFilter filter) =>
    switch (filter) {
      OrderHistoryFilter.active => _activeOrders,
      OrderHistoryFilter.completed => _completedOrders,
      OrderHistoryFilter.cancelled => _cancelledOrders,
    };

final _activeOrders = [
  _order(
    id: 'preview-1',
    number: 'QK-5108',
    earningsPaise: 5100,
    distanceKm: 2.2,
    restaurant: 'Umami',
    restaurantAddress: 'Opposite 207 Park, Lok Nagar, Vikhroli, Mumbai',
    customer: 'Sneha',
    customerAddress: 'Lakeshore Residency, Lokmanya Nagar, Mumbai',
    hour: 10,
  ),
  _order(
    id: 'preview-2',
    number: 'QK-5109',
    earningsPaise: 6000,
    distanceKm: 3.8,
    restaurant: 'Bikkgane Biryani',
    restaurantAddress: 'Shop No. 2, Mahavir Nagar, Chakala, Mumbai',
    customer: 'Sri Vyshnavi',
    customerAddress: 'Vasant Vihar, Powai, Mumbai',
    hour: 10,
    minute: 8,
  ),
  _order(
    id: 'preview-3',
    number: 'QK-5110',
    earningsPaise: 5300,
    distanceKm: 4.0,
    restaurant: "Gopala's Veg Kitchen",
    restaurantAddress: 'Laxmi Udyog Nagar, LBS Marg, Mumbai',
    customer: 'Ketaki Karkhanis',
    customerAddress: 'Riverview Tower, Sion, Mumbai',
    hour: 10,
    minute: 16,
  ),
  _order(
    id: 'preview-4',
    number: 'QK-5111',
    earningsPaise: 5500,
    distanceKm: 4.0,
    restaurant: "Gopala's Veg Kitchen",
    restaurantAddress: 'Laxmi Udyog Nagar, LBS Marg, Mumbai',
    customer: 'Vishakha',
    customerAddress: 'Kanjurmarg East, Mumbai',
    hour: 10,
    minute: 24,
  ),
  _order(
    id: 'preview-5',
    number: 'QK-5112',
    earningsPaise: 5900,
    distanceKm: 4.0,
    restaurant: "Gopala's Veg Kitchen",
    restaurantAddress: 'Laxmi Udyog Nagar, LBS Marg, Mumbai',
    customer: 'Akash Deep',
    customerAddress: 'Ekta Nagar, Bhandup West, Mumbai',
    hour: 10,
    minute: 32,
  ),
  _order(
    id: 'preview-6',
    number: 'QK-5113',
    earningsPaise: 5300,
    distanceKm: 4.0,
    restaurant: "Gopala's Veg Kitchen",
    restaurantAddress: 'Laxmi Udyog Nagar, LBS Marg, Mumbai',
    customer: 'Renuka',
    customerAddress: 'Ambedkar Nagar, Kurla West, Mumbai',
    hour: 10,
    minute: 40,
  ),
];

final _completedOrders = [
  _order(
    id: 'preview-completed-1',
    number: 'QK-5099',
    earningsPaise: 7200,
    distanceKm: 2.5,
    restaurant: 'The Bowl Company',
    restaurantAddress: 'Hiranandani Gardens, Powai, Mumbai',
    customer: 'Aarav',
    customerAddress: 'IIT Area, Powai, Mumbai',
    status: RiderOrderStatus.delivered,
    hour: 9,
  ),
];

final _cancelledOrders = [
  _order(
    id: 'preview-cancelled-1',
    number: 'QK-5098',
    earningsPaise: 0,
    distanceKm: 1.5,
    restaurant: 'FreshMenu',
    restaurantAddress: 'Andheri East, Mumbai',
    customer: 'Nikhil',
    customerAddress: 'Marol, Mumbai',
    status: RiderOrderStatus.cancelled,
    hour: 8,
    minute: 52,
  ),
];

RiderOrderModel _order({
  required String id,
  required String number,
  required int earningsPaise,
  required double distanceKm,
  required String restaurant,
  required String restaurantAddress,
  required String customer,
  required String customerAddress,
  required int hour,
  int minute = 0,
  RiderOrderStatus status = RiderOrderStatus.accepted,
}) =>
    RiderOrderModel(
      id: id,
      orderId: 'order-$id',
      status: status,
      distanceKm: distanceKm,
      earningsPaise: earningsPaise,
      tipsPaise: 0,
      etaMinutes: 18,
      assignedAt: DateTime(2026, 8, 3, hour, minute),
      acceptedAt: DateTime(2026, 8, 3, hour, minute),
      arrivedAt: null,
      pickedUpAt: null,
      outForDeliveryAt: null,
      deliveredAt: status == RiderOrderStatus.delivered
          ? DateTime(2026, 8, 3, hour, minute + 24)
          : null,
      cancelledAt: status == RiderOrderStatus.cancelled
          ? DateTime(2026, 8, 3, hour, minute + 5)
          : null,
      cancellationReason: null,
      restaurant: RestaurantContactModel(
        name: restaurant,
        phone: '9000000000',
        address: restaurantAddress,
        landmark: null,
        latitude: 19.076,
        longitude: 72.8777,
      ),
      order: RestaurantOrderSummary(
        id: 'order-$id',
        orderNumber: number,
        customerName: customer,
        customerPhone: null,
        deliveryAddressLine: customerAddress,
        deliveryCity: 'Mumbai',
        deliveryPincode: '400076',
        deliveryLat: 19.118,
        deliveryLng: 72.906,
        totalPaise: earningsPaise * 10,
        customerNote: null,
        status: status == RiderOrderStatus.cancelled
            ? RestaurantOrderStatus.cancelled
            : status == RiderOrderStatus.delivered
                ? RestaurantOrderStatus.delivered
                : RestaurantOrderStatus.readyForPickup,
        statusHistory: null,
      ),
      pickupQr: null,
      deliveryOtp: null,
    );

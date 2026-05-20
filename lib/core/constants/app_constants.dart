import 'package:flutter/material.dart';

class AppConstants {
  // Spacing system
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacing3XL = 32.0;
  static const double spacing4XL = 40.0;
  static const double spacing5XL = 48.0;

  // Border radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 100.0;

  // Firestore collections
  static const String adminsCollection = 'admins';
  static const String tripsCollection = 'trips';
  static const String membersCollection = 'members';
  static const String expensesCollection = 'expenses';
  static const String paymentsCollection = 'payments';

  // Expense categories
  static const List<String> expenseCategories = [
    'Vehicle Rent',
    'Petrol',
    'Food',
    'Stay',
    'Extra',
  ];

  // Payment methods
  static const List<String> paymentMethods = ['GPay', 'Cash'];

  // Payment statuses
  static const List<String> paymentStatuses = ['Paid', 'Pending', 'Partial'];

  // Currency symbol
  static const String currency = '₹';

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Category icons
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case 'vehicle rent':
      case 'vehicle':
      case 'rent':
        return Icons.directions_car_rounded;
      case 'petrol':
      case 'fuel':
        return Icons.local_gas_station_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'stay':
      case 'hotel':
      case 'accommodation':
        return Icons.hotel_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Payment status icon
  static IconData getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'partial':
        return Icons.timelapse_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

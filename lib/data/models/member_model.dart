import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String tripId;
  final String name;
  final String phone;
  final double amountPaid;
  final String paymentMethod; // GPay, Cash
  final String paymentStatus; // Paid, Pending, Partial
  final DateTime createdAt;
  final DateTime updatedAt;

  MemberModel({
    required this.id,
    required this.tripId,
    required this.name,
    this.phone = '',
    this.amountPaid = 0,
    this.paymentMethod = 'Cash',
    this.paymentStatus = 'Pending',
    required this.createdAt,
    required this.updatedAt,
  });

  MemberModel copyWith({
    String? id,
    String? tripId,
    String? name,
    String? phone,
    double? amountPaid,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'name': name,
      'phone': phone,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

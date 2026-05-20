import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String tripId;
  final String memberId;
  final String memberName;
  final double amount;
  final String paymentMethod; // GPay, Cash
  final DateTime date;
  final String notes;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.tripId,
    required this.memberId,
    required this.memberName,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.notes = '',
    required this.createdAt,
  });

  PaymentModel copyWith({
    String? id,
    String? tripId,
    String? memberId,
    String? memberName,
    double? amount,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'memberId': memberId,
      'memberName': memberName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

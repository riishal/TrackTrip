import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String tripId;
  final String title;
  final String category;
  final String customCategory; // Used when category is 'Extra'
  final double amount;
  final DateTime date;
  final String notes;
  final String addedBy;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    this.customCategory = '',
    required this.amount,
    required this.date,
    this.notes = '',
    this.addedBy = 'Admin',
    required this.createdAt,
  });

  /// Returns the display category (custom name for 'Extra' type)
  String get displayCategory => category == 'Extra' && customCategory.isNotEmpty
      ? customCategory
      : category;

  ExpenseModel copyWith({
    String? id,
    String? tripId,
    String? title,
    String? category,
    String? customCategory,
    double? amount,
    DateTime? date,
    String? notes,
    String? addedBy,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'Extra',
      customCategory: data['customCategory'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'] ?? '',
      addedBy: data['addedBy'] ?? 'Admin',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'title': title,
      'category': category,
      'customCategory': customCategory,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'addedBy': addedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

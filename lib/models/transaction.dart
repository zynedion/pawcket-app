class TransactionModel {
  final int? transactionId;
  final int userId;
  final int categoryId;
  final String transactionType; // 'expense' or 'income'
  final int amountIdr;
  final String? description;
  final String? vendorName;
  final String? paymentMethod; // 'cash', 'debit_card', 'e_wallet', 'bank_transfer'
  final int transactionDate; // UTC milliseconds
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  final bool isSyncedToCloud;
  final double nlpConfidence;

  TransactionModel({
    this.transactionId,
    required this.userId,
    required this.categoryId,
    required this.transactionType,
    required this.amountIdr,
    this.description,
    this.vendorName,
    this.paymentMethod,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSyncedToCloud,
    required this.nlpConfidence,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'user_id': userId,
      'category_id': categoryId,
      'transaction_type': transactionType,
      'amount_idr': amountIdr,
      'description': description,
      'vendor_name': vendorName,
      'payment_method': paymentMethod,
      'transaction_date': transactionDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'is_synced_to_cloud': isSyncedToCloud ? 1 : 0,
      'nlp_confidence': nlpConfidence,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      transactionId: map['transaction_id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int,
      transactionType: map['transaction_type'] as String,
      amountIdr: map['amount_idr'] as int,
      description: map['description'] as String?,
      vendorName: map['vendor_name'] as String?,
      paymentMethod: map['payment_method'] as String?,
      transactionDate: map['transaction_date'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      deletedAt: map['deleted_at'] as int?,
      isSyncedToCloud: (map['is_synced_to_cloud'] as int) == 1,
      nlpConfidence: (map['nlp_confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

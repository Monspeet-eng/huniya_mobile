class WalletModel {
  final int id;
  final int userId;
  final double balance;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }
}

class WalletTransactionModel {
  final int id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String description;
  final String status;
  final DateTime? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      balanceAfter:
          double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

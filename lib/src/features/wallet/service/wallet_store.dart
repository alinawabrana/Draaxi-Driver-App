import 'package:flutter/foundation.dart';

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.dateLabel,
    required this.amount,
    required this.type,
    this.subtitle,
  });

  final String title;
  final String dateLabel;
  final double amount;
  final String type;
  final String? subtitle;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.availableBalance,
    required this.totalSpent,
    required this.transactions,
  });

  final double availableBalance;
  final double totalSpent;
  final List<WalletTransaction> transactions;

  WalletSnapshot copyWith({
    double? availableBalance,
    double? totalSpent,
    List<WalletTransaction>? transactions,
  }) {
    return WalletSnapshot(
      availableBalance: availableBalance ?? this.availableBalance,
      totalSpent: totalSpent ?? this.totalSpent,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletStore {
  WalletStore._();

  static final WalletStore instance = WalletStore._();

  final ValueNotifier<WalletSnapshot> snapshot = ValueNotifier<WalletSnapshot>(
    const WalletSnapshot(
      availableBalance: 500,
      totalSpent: 200,
      transactions: <WalletTransaction>[
        WalletTransaction(
          title: 'Trip Payment',
          dateLabel: 'Today at 09:20 am',
          amount: 570,
          type: 'in',
        ),
        WalletTransaction(
          title: 'Withdrawal',
          dateLabel: 'Yesterday at 08:10 pm',
          amount: -320,
          type: 'out',
        ),
        WalletTransaction(
          title: 'Trip Payment',
          dateLabel: 'Yesterday at 06:42 pm',
          amount: 440,
          type: 'in',
        ),
        WalletTransaction(
          title: 'Service Fee',
          dateLabel: 'Mon at 03:15 pm',
          amount: -45,
          type: 'out',
        ),
      ],
    ),
  );

  static const List<String> _balanceKeys = <String>[
    'wallet_balance',
    'available_balance',
    'balance',
    'wallet_amount',
  ];

  static const List<String> _spentKeys = <String>[
    'total_expend',
    'total_spend',
    'total_spent',
    'spent',
  ];

  static const List<String> _transactionKeys = <String>[
    'transactions',
    'wallet_transactions',
    'wallet_history',
    'history',
  ];

  void seedFromBackend(Map<String, dynamic> payload) {
    final sources = <Map<String, dynamic>>[
      payload,
      if (payload['data'] is Map<String, dynamic>)
        payload['data'] as Map<String, dynamic>,
      if (payload['user'] is Map<String, dynamic>)
        payload['user'] as Map<String, dynamic>,
      if (payload['driver_profile'] is Map<String, dynamic>)
        payload['driver_profile'] as Map<String, dynamic>,
    ];

    final walletMap = _firstNestedMap(sources, const <String>[
      'wallet',
      'wallet_data',
      'wallet_summary',
    ]);
    if (walletMap != null) {
      sources.add(walletMap);
    }

    final availableBalance = _pickDouble(sources, _balanceKeys);
    final totalSpent = _pickDouble(sources, _spentKeys);
    final transactions = _pickTransactions(sources);

    if (availableBalance == null && totalSpent == null && transactions == null) {
      return;
    }

    final current = snapshot.value;
    snapshot.value = current.copyWith(
      availableBalance: availableBalance ?? current.availableBalance,
      totalSpent: totalSpent ?? current.totalSpent,
      transactions: transactions ?? current.transactions,
    );
  }

  void recordServiceFeeDeduction({
    required String rideLabel,
    required double serviceAmount,
    double? totalFare,
  }) {
    if (serviceAmount <= 0) return;

    final current = snapshot.value;
    final nextTransactions = <WalletTransaction>[
      WalletTransaction(
        title: 'Service Fee',
        subtitle: totalFare != null && totalFare > 0
            ? '$rideLabel • Fare \$${totalFare.toStringAsFixed(2)}'
            : rideLabel,
        dateLabel: _nowLabel(),
        amount: -serviceAmount,
        type: 'out',
      ),
      ...current.transactions,
    ];

    snapshot.value = current.copyWith(
      availableBalance: current.availableBalance - serviceAmount,
      totalSpent: current.totalSpent + serviceAmount,
      transactions: nextTransactions,
    );
  }

  static Map<String, dynamic>? _firstNestedMap(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value is Map<String, dynamic>) return value;
      }
    }
    return null;
  }

  static double? _pickDouble(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value.trim());
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  static List<WalletTransaction>? _pickTransactions(
    List<Map<String, dynamic>> sources,
  ) {
    for (final source in sources) {
      for (final key in _transactionKeys) {
        final raw = source[key];
        if (raw is! List) continue;
        final parsed = raw
            .whereType<Map<String, dynamic>>()
            .map(_transactionFromMap)
            .whereType<WalletTransaction>()
            .toList(growable: false);
        if (parsed.isNotEmpty) return parsed;
      }
    }
    return null;
  }

  static WalletTransaction? _transactionFromMap(Map<String, dynamic> raw) {
    final amount = _pickDouble(<Map<String, dynamic>>[raw], const <String>[
      'amount',
      'value',
      'total',
    ]);
    if (amount == null) return null;

    final type = _pickString(raw, const <String>['type', 'direction']) ??
        (amount < 0 ? 'out' : 'in');
    return WalletTransaction(
      title: _pickString(raw, const <String>['name', 'title', 'label']) ??
          'Transaction',
      subtitle: _pickString(
        raw,
        const <String>['subtitle', 'description', 'note'],
      ),
      dateLabel: _pickString(raw, const <String>['date', 'created_at']) ??
          _nowLabel(),
      amount: amount,
      type: type,
    );
  }

  static String? _pickString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _nowLabel() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final meridian = now.hour >= 12 ? 'pm' : 'am';
    return 'Today at $hour:$minute $meridian';
  }
}

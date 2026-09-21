import 'package:draaxi_driver/src/features/wallet/service/wallet_store.dart';
import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF1E1F24)
        : const Color(0xFFF7F7F7);
    final cardBackground = isDark ? const Color(0xFF2A2D34) : Colors.white;
    final accentSoft = isDark
        ? const Color(0xFF35383F)
        : const Color(0xFFFFFBE7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final textSecondary = isDark
        ? const Color(0xFFBFC2C9)
        : const Color(0xFF6D6D6D);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconButton(Icons.menu, isDark),
                  Row(
                    children: [
                      _iconButton(Icons.search, isDark),
                      const SizedBox(width: 8),
                      _iconButton(Icons.notifications_outlined, isDark),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Wallet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF4BE05)),
                    backgroundColor: cardBackground,
                    foregroundColor: const Color(0xFFF4BE05),
                    fixedSize: const Size(160, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add Money',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<WalletSnapshot>(
                valueListenable: WalletStore.instance.snapshot,
                builder: (context, wallet, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: _balanceCard(
                          title: 'Available Balance',
                          amount: _formatCurrency(wallet.availableBalance),
                          background: accentSoft,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _balanceCard(
                          title: 'Total Expend',
                          amount: _formatCurrency(wallet.totalSpent),
                          background: accentSoft,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFFF4BE05),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ValueListenableBuilder<WalletSnapshot>(
                  valueListenable: WalletStore.instance.snapshot,
                  builder: (context, wallet, _) {
                    final transactions = wallet.transactions;
                    return ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final amount = tx.amount;
                        final isOut = tx.type == 'out' || amount < 0;
                        final amountText = isOut
                            ? '-\$${amount.abs().toStringAsFixed(2)}'
                            : '\$${amount.toStringAsFixed(2)}';

                        return Container(
                          decoration: BoxDecoration(
                            color: cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF4BE05)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOut
                                      ? const Color(0xFFFFE3E3)
                                      : const Color(0xFFE2F7E5),
                                ),
                                child: Icon(
                                  isOut
                                      ? Icons.call_made
                                      : Icons.call_received,
                                  color: isOut
                                      ? const Color(0xFFD64242)
                                      : const Color(0xFF22A05D),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.title,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.subtitle == null ||
                                              tx.subtitle!.isEmpty
                                          ? tx.dateLabel
                                          : '${tx.dateLabel} • ${tx.subtitle!}',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                amountText,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, bool isDark) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3E46) : const Color(0xFFFFF1B1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isDark ? const Color(0xFFF4BE05) : const Color(0xFF414141),
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String amount,
    required Color background,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF4BE05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            amount,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';
}

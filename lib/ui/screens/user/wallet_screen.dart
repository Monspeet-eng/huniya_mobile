import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/payment_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchWallet();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nominal top-up yang valid')));
      return;
    }
    final ok = await context.read<PaymentProvider>().topUp(amount);
    if (!mounted) return;
    if (ok) {
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo berhasil ditambahkan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          final wallet = provider.wallet;
          return RefreshIndicator(
            onRefresh: provider.fetchWallet,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo saat ini', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(_currency.format(wallet?.balance ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nominal top-up', prefixText: 'Rp ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                FilledButton(onPressed: provider.isLoading ? null : _topUp, child: const Text('Top Up')),
                const SizedBox(height: 24),
                const Text('Riwayat transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (provider.transactions.isEmpty) const Text('Belum ada transaksi'),
                ...provider.transactions.map((tx) => ListTile(
                  leading: Icon(tx.amount >= 0 ? Icons.add_circle : Icons.remove_circle, color: tx.amount >= 0 ? Colors.green : Colors.red),
                  title: Text(tx.description.isEmpty ? tx.type : tx.description),
                  subtitle: Text(tx.createdAt == null ? '' : DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(tx.createdAt!.toLocal())),
                  trailing: Text(_currency.format(tx.amount), style: TextStyle(color: tx.amount >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

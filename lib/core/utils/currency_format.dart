import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String toRupiah(num amount) {
    return _rupiahFormatter.format(amount);
  }
}

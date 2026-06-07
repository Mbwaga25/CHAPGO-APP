import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CashflowTransaction {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category; // 'fuel', 'maintenance', 'fare', 'food', 'sacco', 'other'
  final DateTime date;
  final String description;

  CashflowTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'description': description,
      };

  factory CashflowTransaction.fromJson(Map<String, dynamic> json) {
    return CashflowTransaction(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: json['type'] as String? ?? 'expense',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      category: json['category'] as String? ?? 'other',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      description: json['description'] as String? ?? '',
    );
  }
}

class CashflowProvider extends ChangeNotifier {
  List<CashflowTransaction> _transactions = [];
  bool _loading = true;
  ApiService? _api;

  List<CashflowTransaction> get transactions => _transactions;
  bool get loading => _loading;

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netCashflow => totalIncome - totalExpense;

  CashflowProvider() {
    _loadTransactions();
  }

  void setApi(ApiService api) {
    _api = api;
    fetchAndSync();
  }

  Future<void> fetchAndSync() async {
    if (_api == null) return;
    _loading = true;
    notifyListeners();
    try {
      final res = await _api!.get('/driver/cashflow');
      final List<dynamic> txsList = res['transactions'] ?? [];
      final backendTxs = txsList.map((item) => CashflowTransaction.fromJson(item)).toList();

      _transactions = backendTxs;
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      final prefs = await SharedPreferences.getInstance();
      final data = _transactions.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('chapgo_cashflow', data);
    } catch (e) {
      debugPrint('Sync failed, loading from local cache: $e');
      await _loadTransactions();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTransactions() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('chapgo_cashflow') ?? [];
      _transactions = data
          .map((item) => CashflowTransaction.fromJson(jsonDecode(item)))
          .toList();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Failed to load cashflow: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
  }) async {
    final tx = CashflowTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      amount: amount,
      category: category,
      date: DateTime.now(),
      description: description,
    );

    _transactions.insert(0, tx);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _transactions.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('chapgo_cashflow', data);

      if (_api != null) {
        await _api!.post(
          '/driver/cashflow',
          body: {
            'id': tx.id,
            'type': tx.type,
            'amount': tx.amount,
            'category': tx.category,
            'description': tx.description,
            'date': tx.date.toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to save or sync cashflow: $e');
    }
  }


  Future<void> clearTransactions() async {
    _transactions.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chapgo_cashflow');
    } catch (e) {
      debugPrint('Failed to clear cashflow: $e');
    }
  }
}

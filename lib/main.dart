import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'theme.dart';

void main() => runApp(const ScientificCalculatorApp());

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'آلة حاسبة علمية',
        theme: CalculatorTheme.dark,
        home: const CalculatorPage(),
      );
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({Key? key}) : super(key: key);
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String expression = '';
  String result = '0';
  bool degrees = true;
  double memory = 0;
  final List<String> history = <String>[];

  void input(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '0';
      } else if (value == 'DEL') {
        if (expression.isNotEmpty) expression = expression.substring(0, expression.length - 1);
      } else if (value == '=') {
        _calculate();
      } else if (value == 'ANS') {
        expression += result == 'Error' ? '' : result;
      } else if (value == '×') {
        expression += '*';
      } else if (value == '÷') {
        expression += '/';
      } else if (value == '−') {
        expression += '-';
      } else if (value == 'π') {
        expression += 'pi';
      } else {
        expression += value;
      }
    });
  }

  void _calculate() {
    if (expression.trim().isEmpty) return;
    try {
      final value = ExpressionParser(expression, degrees: degrees).parse();
      final formatted = _format(value);
      history.insert(0, '$expression = $formatted');
      if (history.length > 12) history.removeLast();
      result = formatted;
    } catch (_) {
      result = 'Error';
    }
  }

  String _format(double value) {
    if (!value.isFinite || value.isNaN) return 'Error';
    if ((value - value.round()).abs() < 1e-10) return value.round().toString();
    return value.toStringAsPrecision(10).replaceFirst(RegExp(r'\.0+$'), '');
  }

  void memoryAction(String action) {
    final current = double.tryParse(result) ?? 0;
    setState(() {
      if (action == 'M+') memory += current;
      if (action == 'M-') memory -= current;
      if (action == 'MR') expression += _format(memory);
      if (action == 'MC') memory = 0;
    });
  }

  void showHistory() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151827),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 360,
          child: Column(
            children: <Widget>[
              const Text('سجل العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Expanded(
                child: history.isEmpty
                    ? const Center(child: Text('لا توجد عمليات بعد'))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: const Icon(Icons.history_rounded, color: CalculatorTheme.cyan),
                          title: Text(history[index], textDirection: TextDirection.ltr),
                          onTap: () {
                            final parts = history[index].split(' = ');
                            setState(() => expression = parts.first);
                            Navigator.pop(context);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = <String>[
      'sin(', 'cos(', 'tan(', 'ln(',
      'log(', 'sqrt(', '^', '!',
      '(', ')', '%', 'DEL',
      '7', '8', '9', '÷',
      '4', '5', '6', '×',
      '1', '2', '3', '−',
      '0', '.', 'π', '+',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('آلة حاسبة علمية', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: <Widget>[
          IconButton(onPressed: showHistory, icon: const Icon(Icons.history_rounded)),
          PopupMenuButton<String>(
            onSelected: memoryAction,
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'M+', child: Text('إضافة إلى الذاكرة M+')),
              PopupMenuItem(value: 'M-', child: Text('طرح من الذاكرة M-')),
              PopupMenuItem(value: 'MR', child: Text('استدعاء الذاكرة MR')),
              PopupMenuItem(value: 'MC', child: Text('مسح الذاكرة MC')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: <Widget>[
              GlassPanel(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(degrees ? 'DEG' : 'RAD', style: const TextStyle(color: CalculatorTheme.cyan, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('M: ${_format(memory)}', style: TextStyle(color: Colors.white.withOpacity(.5))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(expression.isEmpty ? '0' : expression, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 24, color: Colors.white.withOpacity(.62))),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Text(result, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _smallButton(degrees ? 'DEG' : 'RAD', () => setState(() => degrees = !degrees))),
                  const SizedBox(width: 8),
                  Expanded(child: _smallButton('ANS', () => input('ANS'))),
                  const SizedBox(width: 8),
                  Expanded(child: _smallButton('COPY', () => Clipboard.setData(ClipboardData(text: result)))),
                  const SizedBox(width: 8),
                  Expanded(child: _smallButton('AC', () => input('AC'), danger: true)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: keys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.45),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final operator = <String>{'÷', '×', '−', '+', '^', '!', '%', 'DEL'}.contains(key);
                    return _keyButton(key, () => input(key), operator: operator);
                  },
                ),
              ),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => input('='), style: ElevatedButton.styleFrom(backgroundColor: CalculatorTheme.accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: const Text('حساب  =', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallButton(String label, VoidCallback onTap, {bool danger = false}) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: danger ? Colors.redAccent : Colors.white70, side: BorderSide(color: danger ? Colors.redAccent.withOpacity(.4) : Colors.white12), padding: const EdgeInsets.symmetric(vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)));

  Widget _keyButton(String label, VoidCallback onTap, {bool operator = false}) => Material(color: operator ? const Color(0xFF25283D) : const Color(0xFF191C2B), borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Center(child: Text(label, textDirection: TextDirection.ltr, style: TextStyle(fontSize: label.length > 3 ? 15 : 21, fontWeight: FontWeight.w800, color: operator ? CalculatorTheme.cyan : Colors.white)))));
}

class ExpressionParser {
  ExpressionParser(String input, {required this.degrees}) : _input = input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-').replaceAll(' ', '');
  final String _input;
  final bool degrees;
  int _pos = 0;

  double parse() {
    final value = _expression();
    if (_pos != _input.length) throw const FormatException();
    return value;
  }

  double _expression() {
    var value = _term();
    while (_pos < _input.length && (_peek('+') || _peek('-'))) {
      final op = _input[_pos++];
      final next = _term();
      value = op == '+' ? value + next : value - next;
    }
    return value;
  }

  double _term() {
    var value = _power();
    while (_pos < _input.length && (_peek('*') || _peek('/') || _peek('%'))) {
      final op = _input[_pos++];
      final next = _power();
      if (op == '*') value *= next;
      if (op == '/') value /= next;
      if (op == '%') value %= next;
    }
    return value;
  }

  double _power() {
    var value = _unary();
    if (_peek('^')) {
      _pos++;
      value = math.pow(value, _power()).toDouble();
    }
    return value;
  }

  double _unary() {
    if (_peek('+')) { _pos++; return _unary(); }
    if (_peek('-')) { _pos++; return -_unary(); }
    return _postfix();
  }

  double _postfix() {
    var value = _primary();
    while (_peek('!') || _peek('%')) {
      final op = _input[_pos++];
      if (op == '%') value /= 100;
      if (op == '!') value = _factorial(value);
    }
    return value;
  }

  double _primary() {
    if (_peek('(')) {
      _pos++;
      final value = _expression();
      if (!_peek(')')) throw const FormatException();
      _pos++;
      return value;
    }
    if (_pos < _input.length && RegExp(r'[A-Za-z]').hasMatch(_input[_pos])) {
      final start = _pos;
      while (_pos < _input.length && RegExp(r'[A-Za-z]').hasMatch(_input[_pos])) _pos++;
      final name = _input.substring(start, _pos).toLowerCase();
      if (name == 'pi') return math.pi;
      if (name == 'e') return math.e;
      if (!_peek('(')) throw const FormatException();
      _pos++;
      final value = _expression();
      if (!_peek(')')) throw const FormatException();
      _pos++;
      return _function(name, value);
    }
    final start = _pos;
    while (_pos < _input.length && RegExp(r'[0-9.]').hasMatch(_input[_pos])) _pos++;
    if (start == _pos) throw const FormatException();
    return double.parse(_input.substring(start, _pos));
  }

  double _function(String name, double value) {
    final radians = degrees ? value * math.pi / 180 : value;
    if (name == 'sin') return math.sin(radians);
    if (name == 'cos') return math.cos(radians);
    if (name == 'tan') return math.tan(radians);
    if (name == 'sqrt') return math.sqrt(value);
    if (name == 'ln') return math.log(value);
    if (name == 'log') return math.log(value) / math.ln10;
    if (name == 'abs') return value.abs();
    throw const FormatException();
  }

  double _factorial(double value) {
    if (value < 0 || value > 170 || value != value.round()) throw const FormatException();
    var total = 1.0;
    for (var i = 2; i <= value.round(); i++) total *= i;
    return total;
  }

  bool _peek(String char) => _pos < _input.length && _input[_pos] == char;
}
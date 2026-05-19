import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../theme/category_meta.dart';
import '../utils/dates.dart';

class ExpenseDraft {
  final double amount;
  final String description;
  final String categoryId;
  final DateTime date;
  const ExpenseDraft({
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.date,
  });
}

class ExpenseModal extends StatefulWidget {
  final Expense? editing;
  final void Function(ExpenseDraft) onSubmit;
  final VoidCallback? onDelete;

  const ExpenseModal({
    super.key,
    this.editing,
    required this.onSubmit,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    Expense? editing,
    required void Function(ExpenseDraft) onSubmit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.pine.withOpacity(0.35),
      builder: (_) => ExpenseModal(
        editing: editing,
        onSubmit: onSubmit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ExpenseModal> createState() => _ExpenseModalState();
}

class _ExpenseModalState extends State<ExpenseModal> {
  final _amountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _cat = 'food';
  DateTime _date = DateTime.now();
  bool _confirmDel = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(
          e.amount.truncateToDouble() == e.amount ? 0 : 2);
      _nameCtrl.text = e.description;
      _cat = e.categoryId;
      _date = parseIsoDate(e.date);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: Colors.white,
            surface: AppColors.cream,
            onSurface: AppColors.pine,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _valid => double.tryParse(_amountCtrl.text) != null &&
      double.parse(_amountCtrl.text) > 0;

  void _submit() {
    if (!_valid) return;
    final meta = metaFor(_cat);
    widget.onSubmit(ExpenseDraft(
      amount: double.parse(_amountCtrl.text),
      description: _nameCtrl.text.trim().isEmpty
          ? meta.name
          : _nameCtrl.text.trim(),
      categoryId: _cat,
      date: _date,
    ));
    Navigator.of(context).maybePop();
  }

  void _deleteTap() {
    if (!_confirmDel) {
      setState(() => _confirmDel = true);
      return;
    }
    widget.onDelete?.call();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final editing = widget.editing != null;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: AppColors.borderHi),
            left: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pine.withOpacity(0.18),
              offset: const Offset(0, -16),
              blurRadius: 40,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.pine.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      editing ? 'Edit expense' : 'Add expense',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _amountField(),
                const SizedBox(height: 18),
                _label('Description',
                    suffix: '· optional', suffixMuted: true),
                const SizedBox(height: 8),
                _textField(_nameCtrl,
                    hint:
                        'e.g. ${metaFor(_cat).name == 'Food' ? 'Tea at Chaiwala' : metaFor(_cat).name}'),
                const SizedBox(height: 16),
                _label('Date'),
                const SizedBox(height: 8),
                _dateShortcuts(),
                const SizedBox(height: 8),
                _dateRow(),
                const SizedBox(height: 16),
                _label('Category'),
                const SizedBox(height: 10),
                _categoryChips(),
                const SizedBox(height: 22),
                _actions(editing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'AMOUNT',
          style: TextStyle(
            color: AppColors.text3,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'PKR',
              style: TextStyle(
                color: AppColors.text2,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 240),
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  autofocus: true,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: AppColors.text4,
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text, {String? suffix, bool suffixMuted = false}) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.text3,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            suffix,
            style: TextStyle(
              color: suffixMuted ? AppColors.text4 : AppColors.text3,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _textField(TextEditingController c, {String? hint}) {
    return TextField(
      controller: c,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.text4),
        filled: true,
        fillColor: AppColors.bg2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
    );
  }

  Widget _dateShortcuts() {
    final items = const [
      ('Today', 0),
      ('Yesterday', 1),
      ('2 days ago', 2),
    ];
    return Row(
      children: items.map((it) {
        final target = DateTime.now().subtract(Duration(days: it.$2));
        final selected = toIsoDate(_date) == toIsoDate(target);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: it.$1 == '2 days ago' ? 0 : 8),
            child: _SmallToggle(
              label: it.$1,
              active: selected,
              onTap: () => setState(() => _date = target),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateRow() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.text3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dayLabel(_date),
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.text3, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCategories.map((c) {
        final active = c.id == _cat;
        return _CategoryChip(
          meta: c,
          active: active,
          onTap: () => setState(() => _cat = c.id),
        );
      }).toList(),
    );
  }

  Widget _actions(bool editing) {
    return Row(
      children: [
        if (editing && widget.onDelete != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _deleteTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: _confirmDel
                        ? AppColors.expense
                        : AppColors.expenseBg,
                    border: _confirmDel
                        ? null
                        : Border.all(
                            color: AppColors.expense.withOpacity(0.33)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _confirmDel
                        ? [
                            BoxShadow(
                                color: AppColors.expense.withOpacity(0.33),
                                blurRadius: 18)
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 16,
                          color: _confirmDel
                              ? Colors.white
                              : AppColors.expense),
                      const SizedBox(width: 6),
                      Text(
                        _confirmDel ? 'Tap to confirm' : 'Delete',
                        style: TextStyle(
                          color: _confirmDel
                              ? Colors.white
                              : AppColors.expense,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _valid ? 1 : 0.5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _valid ? _submit : null,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _valid
                        ? [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.40),
                              offset: const Offset(0, 10),
                              blurRadius: 22,
                            )
                          ]
                        : null,
                    border: Border.all(
                      color: AppColors.butter.withOpacity(_valid ? 0.45 : 0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      editing ? 'SAVE CHANGES' : 'ADD EXPENSE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16, color: AppColors.text2),
        ),
      ),
    );
  }
}

class _SmallToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SmallToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.teal.withOpacity(0.14)
              : AppColors.bg2,
          border: Border.all(color: active ? AppColors.teal : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.tealDeep : AppColors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryMeta meta;
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.meta, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: AppCurves.spring,
        transform: Matrix4.identity()..scale(active ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? meta.color.withOpacity(0.13)
              : AppColors.bg2,
          border: Border.all(color: active ? meta.color : AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon,
                size: 14, color: active ? meta.color : AppColors.text2),
            const SizedBox(width: 7),
            Text(
              meta.name,
              style: TextStyle(
                color: active ? meta.color : AppColors.text2,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

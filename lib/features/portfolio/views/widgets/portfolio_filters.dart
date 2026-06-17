import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../viewmodels/portfolio_provider.dart';

class FilterBadge extends StatelessWidget {
  final String label;
  final List<String> selectedItems;
  final VoidCallback onTap;

  const FilterBadge({
    super.key,
    required this.label,
    required this.selectedItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedItems.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasSelection ? const Color(0xFF00C49C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasSelection
                ? const Color(0xFF00C49C)
                : const Color(0xFF889492),
            width: 1,
          ),
          boxShadow: hasSelection
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C49C).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasSelection ? '${selectedItems.length} $label' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: hasSelection ? Colors.white : const Color(0xFF5A6664),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: hasSelection ? Colors.white : const Color(0xFF889492),
            ),
          ],
        ),
      ),
    );
  }
}

class DateFilterBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const DateFilterBadge({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C49C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF00C49C) : const Color(0xFF889492),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00C49C).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF5A6664),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : const Color(0xFF5A6664),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF889492),
            ),
          ],
        ),
      ),
    );
  }
}

void showMultiSelectFilterSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required List<String> selectedItems,
  required StateProvider<List<String>> provider,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final List<String> tempSelections = List.from(selectedItems);

      return StatefulBuilder(
        builder: (context, setState) {
          return Consumer(
            builder: (context, ref, child) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E8E7)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E8E7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF01372C),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    tempSelections.clear();
                                  });
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: options.isEmpty
                          ? const Center(child: Text('No options available'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                final isSelected = tempSelections.contains(
                                  option,
                                );
                                return CheckboxListTile(
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF01372C)
                                          : const Color(0xFF5A6664),
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: const Color(0xFF00C49C),
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        tempSelections.add(option);
                                      } else {
                                        tempSelections.remove(option);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(provider.notifier).state = List.from(
                            tempSelections,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

Future<void> showDatePresetFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
  required StateProvider<PortfolioDatePreset> presetProvider,
  required StateNotifierProvider<PortfolioDateRangeNotifier, DateTimeRange>
  rangeProvider,
}) async {
  final currentPreset = ref.read(presetProvider);
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...PortfolioDatePreset.values.map((preset) {
              final isSelected = currentPreset == preset;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? const Color(0xFF00C49C)
                      : const Color(0xFF889492),
                ),
                title: Text(
                  preset.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFF5A6664),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (preset == PortfolioDatePreset.custom) {
                    _selectCustomDateRange(
                      context: context,
                      ref: ref,
                      presetProvider: presetProvider,
                      rangeProvider: rangeProvider,
                    );
                  } else {
                    ref.read(presetProvider.notifier).state = preset;
                  }
                },
              );
            }),
          ],
        ),
      );
    },
  );
}

Future<void> _selectCustomDateRange({
  required BuildContext context,
  required WidgetRef ref,
  required StateProvider<PortfolioDatePreset> presetProvider,
  required StateNotifierProvider<PortfolioDateRangeNotifier, DateTimeRange>
  rangeProvider,
}) async {
  final currentRange = ref.read(rangeProvider);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return PremiumCustomDateRangePicker(
        initialDateRange: currentRange,
        onRangeSelected: (picked) {
          ref.read(presetProvider.notifier).state = PortfolioDatePreset.custom;
          ref.read(rangeProvider.notifier).setCustomRange(picked);
        },
      );
    },
  );
}

class PremiumCustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final ValueChanged<DateTimeRange> onRangeSelected;

  const PremiumCustomDateRangePicker({
    super.key,
    this.initialDateRange,
    required this.onRangeSelected,
  });

  @override
  State<PremiumCustomDateRangePicker> createState() =>
      _PremiumCustomDateRangePickerState();
}

class _PremiumCustomDateRangePickerState
    extends State<PremiumCustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;

    // Focus on the start date's month, or current month if null
    final initialFocus = _startDate ?? DateTime.now();
    _focusedMonth = DateTime(initialFocus.year, initialFocus.month, 1);
  }

  void _onDateTapped(DateTime date) {
    // Prevent selecting future dates
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (date.isAfter(endOfToday)) return;

    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (date.isBefore(_startDate!)) {
        // Tapped a date before the current start date, set it as the new start date
        _startDate = date;
      } else {
        // Tapped a date after (or equal to) the start date, set it as the end date
        _endDate = date;
      }
    });
  }

  void _applyPreset(PortfolioDatePreset preset) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final endOfYesterday = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      23,
      59,
      59,
      999,
    );

    DateTime start;
    DateTime end = endOfYesterday;

    switch (preset) {
      case PortfolioDatePreset.last7Days:
        start = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day - 6,
          0,
          0,
          0,
        );
        break;
      case PortfolioDatePreset.last30Days:
        start = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day - 29,
          0,
          0,
          0,
        );
        break;
      case PortfolioDatePreset.last12Months:
        start = DateTime(
          yesterday.year - 1,
          yesterday.month,
          yesterday.day + 1,
          0,
          0,
          0,
        );
        break;
      case PortfolioDatePreset.allTime:
        start = DateTime(2010, 1, 1, 0, 0, 0);
        break;
      case PortfolioDatePreset.custom:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _focusedMonth = DateTime(start.year, start.month, 1);
    });
  }

  Widget _buildPresetPill(String label, PortfolioDatePreset preset) {
    return InkWell(
      onTap: () => _applyPreset(preset),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E8E7)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5A6664),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstDayOffset =
        firstDayOfMonth.weekday % 7; // Sunday is 0, Monday is 1...

    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final totalDaysSelected = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : (_startDate != null ? 1 : 0);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E8E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Date Range',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F6F6),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF5A6664),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected Start & End Date Display Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _endDate == null && _startDate != null
                          ? const Color(0xFF00C49C)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'START DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF889492),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startDate != null
                            ? DateFormat('EEE, MMM d, y').format(_startDate!)
                            : 'Select start',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _startDate != null
                              ? AppTheme.primaryColor
                              : const Color(0xFF889492),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF889492),
                  size: 20,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _startDate != null && _endDate != null
                          ? const Color(0xFF00C49C)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'END DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF889492),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _endDate != null
                            ? DateFormat('EEE, MMM d, y').format(_endDate!)
                            : 'Select end',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _endDate != null
                              ? AppTheme.primaryColor
                              : const Color(0xFF889492),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calendar Navigation Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F6F6),
                ),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F6F6),
                ),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {
                  final nextMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                    1,
                  );
                  if (nextMonth.isAfter(DateTime(today.year, today.month, 1))) {
                    return; // Prevent navigating to future months
                  }
                  setState(() {
                    _focusedMonth = nextMonth;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((day) {
              return Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF889492),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid (Constant Height)
          SizedBox(
            height: 240,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1.15,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                DateTime cellDate;
                bool isCurrentMonth = true;

                if (index < firstDayOffset) {
                  final prevMonth = month == 1
                      ? DateTime(year - 1, 12, 1)
                      : DateTime(year, month - 1, 1);
                  final daysInPrevMonth = DateUtils.getDaysInMonth(
                    prevMonth.year,
                    prevMonth.month,
                  );
                  final day = daysInPrevMonth - firstDayOffset + index + 1;
                  cellDate = DateTime(prevMonth.year, prevMonth.month, day);
                  isCurrentMonth = false;
                } else if (index < firstDayOffset + daysInMonth) {
                  final day = index - firstDayOffset + 1;
                  cellDate = DateTime(year, month, day);
                } else {
                  final nextMonth = month == 12
                      ? DateTime(year + 1, 1, 1)
                      : DateTime(year, month + 1, 1);
                  final day = index - firstDayOffset - daysInMonth + 1;
                  cellDate = DateTime(nextMonth.year, nextMonth.month, day);
                  isCurrentMonth = false;
                }

                final isToday = DateUtils.isSameDay(cellDate, today);
                final isStart =
                    _startDate != null &&
                    DateUtils.isSameDay(cellDate, _startDate!);
                final isEnd =
                    _endDate != null &&
                    DateUtils.isSameDay(cellDate, _endDate!);
                final isMiddle =
                    _startDate != null &&
                    _endDate != null &&
                    cellDate.isAfter(_startDate!) &&
                    cellDate.isBefore(_endDate!);
                final isFuture = cellDate.isAfter(endOfToday);

                // Range background shading capsule visual
                Widget backgroundShade = const SizedBox.shrink();
                if (_startDate != null && _endDate != null) {
                  if (isMiddle) {
                    backgroundShade = Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0x2600C49C), // 15% opacity teal
                    );
                  } else if (isStart) {
                    backgroundShade = Row(
                      children: [
                        const Spacer(),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0x2600C49C),
                          ),
                        ),
                      ],
                    );
                  } else if (isEnd) {
                    backgroundShade = Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0x2600C49C),
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  }
                }

                // Text and active circle styling
                Color textColor;
                FontWeight fontWeight = FontWeight.w600;
                BoxDecoration? foregroundDecoration;

                if (isFuture) {
                  textColor = const Color(0xFFCCD6D4);
                } else if (isStart || isEnd) {
                  textColor = Colors.white;
                  fontWeight = FontWeight.w800;
                  foregroundDecoration = const BoxDecoration(
                    color: Color(0xFF00C49C),
                    shape: BoxShape.circle,
                  );
                } else if (isMiddle) {
                  textColor = AppTheme.primaryColor;
                  fontWeight = FontWeight.w800;
                } else if (!isCurrentMonth) {
                  textColor = const Color(0xFFCCD6D4);
                } else {
                  textColor = AppTheme.primaryColor;
                  if (isToday) {
                    fontWeight = FontWeight.w800;
                  }
                }

                Widget cellContent = Center(
                  child: Text(
                    cellDate.day.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: fontWeight,
                      color: textColor,
                    ),
                  ),
                );

                if (isToday && !isStart && !isEnd) {
                  cellContent = Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 2,
                        child: Text(
                          cellDate.day.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: fontWeight,
                            color: textColor,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C49C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return GestureDetector(
                  onTap: isFuture ? null : () => _onDateTapped(cellDate),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    children: [
                      backgroundShade,
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 34,
                          height: 34,
                          decoration: foregroundDecoration,
                          child: cellContent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Preset Buttons Row
          const Text(
            'QUICK PRESETS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF889492),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildPresetPill('Last 7 Days', PortfolioDatePreset.last7Days),
                const SizedBox(width: 8),
                _buildPresetPill(
                  'Last 30 Days',
                  PortfolioDatePreset.last30Days,
                ),
                const SizedBox(width: 8),
                _buildPresetPill(
                  'Last 12 Months',
                  PortfolioDatePreset.last12Months,
                ),
                const SizedBox(width: 8),
                _buildPresetPill('All Time', PortfolioDatePreset.allTime),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Action Info and Apply Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalDaysSelected > 0
                    ? 'Selected: $totalDaysSelected ${totalDaysSelected == 1 ? 'day' : 'days'}'
                    : 'No selection',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startDate != null
                      ? () {
                          final start = DateTime(
                            _startDate!.year,
                            _startDate!.month,
                            _startDate!.day,
                            0,
                            0,
                            0,
                          );
                          final end = _endDate != null
                              ? DateTime(
                                  _endDate!.year,
                                  _endDate!.month,
                                  _endDate!.day,
                                  23,
                                  59,
                                  59,
                                )
                              : DateTime(
                                  _startDate!.year,
                                  _startDate!.month,
                                  _startDate!.day,
                                  23,
                                  59,
                                  59,
                                );
                          widget.onRangeSelected(
                            DateTimeRange(start: start, end: end),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    disabledBackgroundColor: const Color(0xFFE5E8E7),
                    disabledForegroundColor: const Color(0xFF889492),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Range',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

///
import 'package:flutter/material.dart';
import 'package:flutter_input/flutter_input.dart';
import 'package:intl/intl.dart';

/// Provides an input widget for a date.
///
/// The date is displayed together with an icon. Tapping it opens a dialog box with
/// a date picker. The picker can be fully customized.
///
/// To have a date in the past, set [lastDate] to `DateTime.now()` or just add the validator
/// `validators: [(v) => past( v ),]`. Same with [firstDate].
///
/// TODO \[X\] year becomes TextField
/// TODO \[ \] Internationalize this input widget: day names, month names, tooltips, display format, first day of week
///
/// See [InputField] for all common parameters.
class InputCalendar extends InputField<DateTime> {
  /// Pattern to format the displayed date. Defaults to ISO 8601 'yyyy-MM-dd'.
  final String datePattern;

  /// The date picker will not go before [firstDate] if this is set and not after [lastDate]
  /// if this is set. Both values default to `null`.
  final DateTime firstDate, lastDate;
  final double size;

  /// Contains all the customizable styles for the date picker. See [CalendarStyles].
  final CalendarStyles styles;

  InputCalendar({
    Key key,
    bool autovalidate = false,
    this.datePattern = 'yyyy-MM-dd',
    InputDecoration decoration,
    bool enabled,
    this.firstDate,
    this.lastDate,
    DateTime initialValue,
    ValueChanged<DateTime> onChanged,
    ValueSetter<DateTime> onSaved,
    String path,
    this.size = 8 * kMinInteractiveDimension,
    this.styles,
    List<InputValidator> validators,
  })  : assert(size == null || size >= 8 * kMinInteractiveDimension),
        super(
          key: key,
          autovalidate: autovalidate,
          decoration: decoration,
          enabled: enabled,
          initialValue: initialValue,
          onChanged: onChanged,
          onSaved: onSaved,
          path: path,
          validators: validators,
        );

  @override
  _InputCalendarState createState() => _InputCalendarState();
}

class _InputCalendarState extends InputFieldState<DateTime> {
  @override
  InputCalendar get widget => super.widget;

  @override
  Widget build(BuildContext context) {
    DateTime date = value ?? widget.initialValue ?? DateTime.now();
    return super.buildInputField(
      context,
      Container(
        child: GestureDetector(
          child: Row(
            children: <Widget>[
              Text('${DateFormat(widget.datePattern).format(date)}'),
              Icon(Icons.date_range),
            ],
          ),
          onTap: isEnabled()
              ? () async {
                  DateTime newDate = await showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                            child: _InputCalendarPicker(
                          baseWidget: widget,
                          pickerDate: date,
                        ));
                      });
                  didChange(newDate);
                }
              : null,
        ),
      ),
    );
  }
}

/// The calendar picker is displayed in a dialog box. It can either be aborted or closed by
/// selecting today or any other day from the calendar grid.
class _InputCalendarPicker extends StatefulWidget {
  final InputCalendar baseWidget;
  final DateTime pickerDate;

  _InputCalendarPicker({
    @required this.baseWidget,
    @required this.pickerDate,
  });

  @override
  _InputCalendarPickerState createState() => _InputCalendarPickerState(pickerDate);
}

class _InputCalendarPickerState extends State<_InputCalendarPicker> {
  static final List<String> _monthNamesLong = [
    'January',
    'February',
    'March',
    'April',
    'Mai',
    'June',
    'Juli',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static final List<String> _monthNamesShort = [
    'Jan.',
    'Feb.',
    'Mar.',
    'Apr.',
    'Mai.',
    'Jun.',
    'Jul.',
    'Aug.',
    'Sep.',
    'Oct.',
    'Nov.',
    'Dec.'
  ];

  static final List<String> _weekDays = ['W', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  final List<DropdownMenuItem<int>> _monthItemsLong = [];
  final List<DropdownMenuItem<int>> _monthItemsShort = [];

  // --- used to analyze gestures
  double _dx, _dy;

  final TextEditingController _yearController = TextEditingController();

  DateTime currentSelectedDate;

  double monthGridCellDimensionFactor;

  _InputCalendarPickerState(DateTime pickerDate) {
    currentSelectedDate = pickerDate;
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _monthNamesLong.length; i++) {
      _monthItemsLong.add(DropdownMenuItem<int>(
        child: Text(_monthNamesLong[i]),
        value: i + 1,
      ));
    }
    for (int i = 0; i < _monthNamesShort.length; i++) {
      _monthItemsShort.add(DropdownMenuItem<int>(
        child: Text(_monthNamesShort[i]),
        value: i + 1,
      ));
    }
  }

  /// Builds the calendar picker in a dialog overlay.
  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context).orientation == Orientation.portrait
        ? monthGridCellDimensionFactor = 1.5
        : monthGridCellDimensionFactor = 1.8;
    Widget tableHeader = _buildHeader(context);
    Widget monthYearSelections = _buildMonthYearSelections(context);
    Widget calendarTable = _buildTable(context);
    Widget tableFooter = _buildFooter(context);

    Widget calendarPicker;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      // is portrait
      calendarPicker = Material(
        child: SingleChildScrollView(
          child: Container(
            width: 8 * (kMinInteractiveDimension / monthGridCellDimensionFactor),
            child: Column(
              children: <Widget>[
                tableHeader,
                monthYearSelections,
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: calendarTable,
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    _dx = details.delta.dx;
                  },
                  onHorizontalDragEnd: (DragEndDetails details) {
                    _setDisplayedMonth(delta: (_dx > 0) ? -1 : 1);
                  },
                  onVerticalDragUpdate: (details) {
                    _dy = details.delta.dy;
                  },
                  onVerticalDragEnd: (DragEndDetails details) {
                    _setDisplayedMonth(delta: (_dy > 0) ? -1 : 1);
                  },
                ),
                tableFooter,
              ],
            ),
          ),
        ),
      );
    } else {
      // is landscape
      calendarPicker = Material(
        child: SingleChildScrollView(
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: widget.baseWidget.styles?.dateStyle?.textStyle.fontSize * 6,
                  child: tableHeader,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    monthYearSelections,
                    Container(
                      width: 10 * (kMinInteractiveDimension / monthGridCellDimensionFactor),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: calendarTable,
                        onHorizontalDragUpdate: (DragUpdateDetails details) {
                          _dx = details.delta.dx;
                        },
                        onHorizontalDragEnd: (DragEndDetails details) {
                          _setDisplayedMonth(delta: (_dx > 0) ? -1 : 1);
                        },
                        onVerticalDragUpdate: (details) {
                          _dy = details.delta.dy;
                        },
                        onVerticalDragEnd: (DragEndDetails details) {
                          _setDisplayedMonth(delta: (_dy > 0) ? -1 : 1);
                        },
                      ),
                    ),
                    tableFooter,
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return calendarPicker;
  }

  @override
  void dispose() {
    if (_yearController != null) {
      _yearController.dispose();
    }
    super.dispose();
  }

  Widget _buildHeader(BuildContext context) {
    String monthYearText;
    double width;
    double height;
    EdgeInsets paddingsWeekDay;
    EdgeInsets paddingsDay;
    EdgeInsets monthYear;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      width = 8 * kMinInteractiveDimension;
      monthYearText = _monthNamesLong[currentSelectedDate.month - 1] +
          ' ' +
          currentSelectedDate.year.toString();
      paddingsWeekDay = EdgeInsets.only(top: 5.0, bottom: 5.0);
      paddingsDay = EdgeInsets.only(bottom: 5.0);
      monthYear = EdgeInsets.only(bottom: 5.0);
    } else {
      paddingsWeekDay = EdgeInsets.all(5.0);
      paddingsDay = EdgeInsets.all(5.0);
      monthYear = EdgeInsets.all(5.0);
      height = (7 * (kMinInteractiveDimension / monthGridCellDimensionFactor)) +
          (1 * kMinInteractiveDimension) +
          10.0;
      monthYearText = _monthNamesShort[currentSelectedDate.month - 1] +
          ' ' +
          currentSelectedDate.year.toString();
    }
    return Container(
      decoration: widget.baseWidget.styles?.dateStyle?.decoration,
      width: width,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: paddingsWeekDay,
            child: Text(
              _weekDays[currentSelectedDate.weekday],
              style: widget.baseWidget.styles?.dateStyle?.textStyle,
            ),
          ),
          Padding(
            padding: paddingsDay,
            child: Text(
              currentSelectedDate.day.toString(),
              style: widget.baseWidget.styles?.dateStyle?.textStyle.copyWith(
                  fontSize: widget.baseWidget.styles?.dateStyle?.textStyle.fontSize * 2),
            ),
          ),
          Padding(
            padding: monthYear,
            child: Text(
              monthYearText,
              style: widget.baseWidget.styles?.dateStyle?.textStyle,
            ),
          ),
        ],
      ),
    );
  }

  // Builds the header of the calendar picker with close, previous month,
  // month and year, next month and today.
  Widget _buildMonthYearSelections(BuildContext context) {
    Widget monthWidget = _buildMonthWidget();
    Widget yearWidget = _buildYearWidget();
    return Container(
      padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                child: Icon(Icons.chevron_left),
              ),
              onTap: () => _setDisplayedMonth(delta: -1),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: monthWidget,
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: yearWidget,
          ),
          Padding(
            padding: EdgeInsets.only(left: 5.0, right: 5.0),
            child: GestureDetector(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(15.0),
                  ),
                ),
                child: Icon(Icons.chevron_right),
              ),
              onTap: () => _setDisplayedMonth(delta: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthWidget() {
    List<DropdownMenuItem<int>> monthItems;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      // is portrait
      monthItems = _monthItemsShort;
    } else {
      // is landscape
      monthItems = _monthItemsLong;
    }
    return Container(
      padding: EdgeInsets.only(left: 5.0),
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isDense: true,
          icon: null,
          items: monthItems,
          value: currentSelectedDate.month,
          onChanged: (int v) {
            setState(() {
              currentSelectedDate =
                  DateTime(currentSelectedDate.year, v, currentSelectedDate.day);
            });
          },
        ),
      ),
    );
  }

  Widget _buildYearWidget() {
    int year = currentSelectedDate.year;
    _yearController.text = '$year';
    return Container(
        padding: EdgeInsets.only(left: 5.0),
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.0,
          ),
        ),
        child: SizedBox(
          width: 50,
          child: TextField(
            buildCounter: _noCounterHandler,
            controller: _yearController,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(2.0),
              isDense: true,
            ),
            enabled: true,
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
            maxLength: 4,
            style: new TextStyle(color: Colors.black),
            onSubmitted: (v) => _setDisplayedMonth(
              year: int.tryParse(v),
            ),
          ),
        ));
  }

  /// Builds the calendar. It has a header row with column names and
  /// 6 rows with week number and the days of the selected month.
  Widget _buildTable(BuildContext context) {
    List<TableRow> rows = [];

    //--- First row contains column headers
    List<Widget> tableCells =
        _weekDays.map((e) => _buildCell(e, widget.baseWidget.styles.headerStyle)).toList();
    rows.add(TableRow(children: tableCells));

    // --- Compute number of days from previous month
    DateTime displayMonth =
        DateTime(currentSelectedDate.year, currentSelectedDate.month, 1);
    DateTime displayDay = displayMonth.subtract(Duration(days: displayMonth.weekday - 1));
    rows.add(_buildRow(displayDay, widget.baseWidget.styles.prevMonthStyle));
    displayDay = displayDay.add(Duration(days: 7));
    for (int i = 1; i < 6; i++) {
      rows.add(_buildRow(displayDay, widget.baseWidget.styles.nextMonthStyle));
      displayDay = displayDay.add(Duration(days: 7));
    }
    return Table(
      children: rows,
    );
  }

  /// Adds one row to the table with week number and 7 day numbers
  TableRow _buildRow(DateTime date, CalendarStyle otherMonthStyle) {
    CalendarStyle dayStyle;
    List<Widget> cells = [];
    cells.add(_buildCell(
      '${date.weekOfYear()}',
      widget.baseWidget.styles.weekStyle,
    ));
    for (int i = 0; i < 7; i++) {
      DateTime selectedDate = date;
      if (date.isBetween(widget.baseWidget.firstDate, widget.baseWidget.lastDate)) {
        if (selectedDate.isOnSameDayAs(DateTime.now())) {
          dayStyle = widget.baseWidget.styles.todayStyle;
        } else if (selectedDate.isOnSameDayAs(currentSelectedDate)) {
          dayStyle = widget.baseWidget.styles.selectedStyle;
        } else {
          dayStyle = (selectedDate.month == currentSelectedDate.month)
              ? widget.baseWidget.styles.monthStyle
              : otherMonthStyle;
        }
        cells.add(_buildCell('${date.day}', dayStyle, onTapHandler: () {
          setState(() {
            currentSelectedDate = selectedDate;
          });
          //Navigator.of(context).pop(another);
        }));
      } else {
        cells.add(Container());
      }
      date = date.add(Duration(days: 1));
    }
    return TableRow(children: cells);
  }

  Widget _buildCell(String text, CalendarStyle style, {GestureTapCallback onTapHandler}) {
    Widget cell = Container(
      decoration: style?.decoration,
      height: kMinInteractiveDimension / monthGridCellDimensionFactor,
      width: kMinInteractiveDimension / monthGridCellDimensionFactor,
      child: Center(
        child: Text(
          text,
          style: style?.textStyle,
        ),
      ),
    );
    return (onTapHandler == null)
        ? cell
        : GestureDetector(
            child: cell,
            onTap: onTapHandler,
          );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              setState(() {
                currentSelectedDate = DateTime.now();
              });
            },
            child: Icon(Icons.today),
          ),
          Padding(
            padding: EdgeInsets.only(left: 25.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(widget.pickerDate),
              child: Icon(Icons.cancel),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 25.0, right: 25.0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(currentSelectedDate),
              child: Icon(Icons.done),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noCounterHandler(BuildContext context,
      {int currentLength, bool isFocused, int maxLength}) {
    return null;
  }

  /// Sets [year] and / or [month] or applies [delta] in months.
  ///
  /// Setting [delta] in number of months changes the year accordingly.
  /// Ensures that new month and year are within [InputCalendar.firstDate] and
  /// [InputCalendar.lastDate] if these are not null.
  void _setDisplayedMonth({int year, int month, int delta}) {
    setState(() {
      year ??= currentSelectedDate.year;
      month ??= currentSelectedDate.month;
      if (delta != null) {
        month = month + delta;
        while (month < 1) {
          month = month + 12;
          year--;
        }
        while (month > 12) {
          month = month - 12;
          year++;
        }
      }
      // Only set if within borders
      if (DateHelper.isBetween(
          lower: widget.baseWidget.firstDate,
          upper: widget.baseWidget.lastDate,
          year: year,
          month: month)) {
        currentSelectedDate = DateTime(year, month, currentSelectedDate.day);
      }
    });
  }
}

/// All styles for a calendar.
///
/// This class can be set once and then used for all calendars.
class CalendarStyles {
  /// Styles the written selected date on top or left of the picker
  final CalendarStyle dateStyle,

      /// Styles the first row of the picker which contains the column names.
      headerStyle,

      /// Styles the days in the currently selected month.
      monthStyle,

      /// Styles the days which are displayed from the next month.
      nextMonthStyle,

      /// Styles the days which are displayed from the previous month.
      prevMonthStyle,

      /// Styles today
      todayStyle,

      /// Styles selected
      selectedStyle,

      /// Styles the column which contains the number of the week
      weekStyle;

  const CalendarStyles({
    this.dateStyle = const CalendarStyle(
        decoration: BoxDecoration(color: Colors.lightBlueAccent),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24.0,
        )),
    this.headerStyle =
        const CalendarStyle(decoration: BoxDecoration(color: Colors.amberAccent)),
    this.monthStyle = const CalendarStyle(textStyle: TextStyle(color: Colors.black)),
    this.nextMonthStyle = const CalendarStyle(textStyle: TextStyle(color: Colors.black38)),
    this.prevMonthStyle = const CalendarStyle(textStyle: TextStyle(color: Colors.black38)),
    this.todayStyle = const CalendarStyle(
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
    this.selectedStyle = const CalendarStyle(
        decoration: BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
    this.weekStyle = const CalendarStyle(decoration: BoxDecoration(color: Colors.black12)),
  });
}

/// Styles for an [InputCalendar].
class CalendarStyle {
  final Decoration decoration;
  final TextStyle textStyle;

  const CalendarStyle({
    this.decoration,
    this.textStyle,
  });
}

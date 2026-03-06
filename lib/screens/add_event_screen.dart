import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/section_card.dart';
import '../widgets/label.dart';
import '../widgets/time_picker.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddEventScreen({super.key, required this.selectedDate});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructorController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxCapacityController = TextEditingController(text: '20');

  String _selectedRoom = 'Room A';
  String _selectedType = 'Class';
  List<String> _selectedRanks = [];
  List<String> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  final List<String> _rooms = ['Room A', 'Room B', 'Room C'];
  final List<String> _types = ['Class', 'Workshop', 'Tournament', 'Event'];
  final List<String> _daysOfWeek = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  final List<String> _daysOfWeekFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  final List<String> _allRanks = [
    'White Belt', 'Yellow Belt', 'Green Belt',
    'Blue Belt', 'Brown Belt', 'Red Belt', 'Black Belt',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _priceController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    // override theme so time picker uses neutral colors instead of app accent
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFFCC0000),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Colors.white,
            dialBackgroundColor: const Color(0xFFF5F5F5),
            hourMinuteColor: const Color(0xFFF5F5F5),
            hourMinuteTextColor: Colors.black87,
            dayPeriodColor: const Color(0xFFF5F5F5),
            dayPeriodTextColor: Colors.black87,
            entryModeIconColor: Colors.grey,
            helpTextStyle: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (!endDateTime.isAfter(startDateTime)) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('events').add({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'instructor': _instructorController.text.trim(),
        'requiredRanks': _selectedRanks,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'room': _selectedRoom,
        'maxCapacity': int.tryParse(_maxCapacityController.text) ?? 20,
        'currentEnrollment': 0,
        'description': null,
        'requirements': null,
        'daysOfWeek': _selectedDays,
        'startHour': _startTime.hour,
        'startMinute': _startTime.minute,
        'endHour': _endTime.hour,
        'endMinute': _endTime.minute,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating class: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Create class',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // days of week
              SectionCard(
                children: [
                  Label('Days'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_daysOfWeek.length, (i) {
                      final full = _daysOfWeekFull[i];
                      final short = _daysOfWeek[i];
                      final selected = _selectedDays.contains(full);
                      return GestureDetector(
                        onTap: () => setState(() =>
                        selected ? _selectedDays.remove(full) : _selectedDays.add(full)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFCC0000) : const Color(0xFFF0F0F0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              short[0], // just the first letter, M T W T F S S
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // change time of class
              Row(
                children: [
                  Expanded(
                    child: SectionCard(
                      children: [
                        Label('Start time'),
                        const SizedBox(height: 10),
                        TimePicker(
                          time: _startTime.format(context),
                          onTap: () => _selectTime(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SectionCard(
                      children: [
                        Label('End time'),
                        const SizedBox(height: 10),
                        TimePicker(
                          time: _endTime.format(context),
                          onTap: () => _selectTime(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // class details
              SectionCard(
                children: [
                  Label('Class name'),
                  const SizedBox(height: 6),
                  _field(
                    controller: _nameController,
                    hint: 'eg. Advanced Sparring (optional)',
                  ),
                  const SizedBox(height: 16),
                  Label('Instructor'),
                  const SizedBox(height: 6),
                  _field(
                    controller: _instructorController,
                    hint: 'eg. SBN Lisa',
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter instructor name' : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // type and room
              SectionCard(
                children: [
                  Label('Type'),
                  const SizedBox(height: 6),
                  _dropdown<String>(
                    value: _selectedType,
                    items: _types,
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  Label('Room'),
                  const SizedBox(height: 6),
                  _dropdown<String>(
                    value: _selectedRoom,
                    items: _rooms,
                    onChanged: (v) => setState(() => _selectedRoom = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // capacity and price
              SectionCard(
                children: [
                  Label('Max capacity'),
                  const SizedBox(height: 6),
                  _field(
                    controller: _maxCapacityController,
                    hint: '20',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if ((int.tryParse(v) ?? 0) <= 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Label('Price (optional)'),
                  const SizedBox(height: 6),
                  _field(
                    controller: _priceController,
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    prefix: const Text('\$  ', style: TextStyle(color: Colors.black54)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // required ranks
              SectionCard(
                children: [
                  Label('Required ranks'),
                  const SizedBox(height: 2),
                  Text(
                    'Leave empty for all ranks',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allRanks.map((rank) {
                      final selected = _selectedRanks.contains(rank);
                      return GestureDetector(
                        onTap: () => setState(() =>
                        selected ? _selectedRanks.remove(rank) : _selectedRanks.add(rank)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFCC0000) : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rank,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // save class
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createEvent,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000),
                    disabledBackgroundColor: const Color(0xFFCC0000).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Create Event',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // shared text field widget decoration
  Widget _field({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? prefix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefix: prefix,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
      ),
    );
  }

  // shared dropdown widget
  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
    );
  }
}


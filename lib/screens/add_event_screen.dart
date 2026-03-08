import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;
  const AddEventScreen({super.key, required this.selectedDate});

  @override
  State<AddEventScreen> createState() => _AddEventState();
}

class _AddEventState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _instructorCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '20');

  String _room = 'Room A';
  String _type = 'Class';
  List<String> _ranks = [];
  List<String> _days = [];
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;

  final List<String> _rooms = ['Room A', 'Room B', 'Room C'];
  final List<String> _types = ['Class', 'Workshop', 'Tournament', 'Event'];
  // short labels for day toggles, full names stored in _days
  final List<String> _daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _daysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _allRanks = [
    'White Belt', 'Yellow Belt', 'Green Belt',
    'Blue Belt', 'Brown Belt', 'Red Belt', 'Black Belt',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instructorCtrl.dispose();
    _priceCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
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
            helpTextStyle: const TextStyle(color: Colors.black54, fontSize: 12, letterSpacing: 1),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final startDT = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day,
        _start.hour, _start.minute,
      );
      final endDT = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day,
        _end.hour, _end.minute,
      );

      // validate time range before writing
      if (!endDT.isAfter(startDT)) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('events').add({
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'startTime': Timestamp.fromDate(startDT),
        'endTime': Timestamp.fromDate(endDT),
        'instructor': _instructorCtrl.text.trim(),
        'requiredRanks': _ranks,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'room': _room,
        'maxCapacity': int.tryParse(_capCtrl.text) ?? 20,
        'currentEnrollment': 0,
        'description': null,
        'requirements': null,
        'daysOfWeek': _days,
        'startHour': _start.hour,
        'startMinute': _start.minute,
        'endHour': _end.hour,
        'endMinute': _end.minute,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Create class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text('Days', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 10),
              // day toggle row -- stores full name, displays abbreviated
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_daysShort.length, (i) {
                  final full = _daysFull[i];
                  final short = _daysShort[i];
                  final sel = _days.contains(full);
                  return GestureDetector(
                    onTap: () => setState(() =>
                    sel ? _days.remove(full) : _days.add(full)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFCC0000) : const Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          short[0],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start time', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickTime(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(_start.format(context), style: const TextStyle(fontSize: 14))),
                                Icon(Icons.access_time, size: 15, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End time', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _pickTime(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(_end.format(context), style: const TextStyle(fontSize: 14))),
                                Icon(Icons.access_time, size: 15, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('Class name', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _field(controller: _nameCtrl, hint: 'eg. Advanced Sparring (optional)'),
              const SizedBox(height: 16),
              Text('Instructor', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _field(
                controller: _instructorCtrl,
                hint: 'eg. SBN Lisa',
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter instructor name' : null,
              ),
              const SizedBox(height: 12),

              Text('Type', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _drop<String>(value: _type, items: _types, onChanged: (v) => setState(() => _type = v!)),
              const SizedBox(height: 16),
              Text('Room', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _drop<String>(value: _room, items: _rooms, onChanged: (v) => setState(() => _room = v!)),
              const SizedBox(height: 12),

              Text('Max capacity', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _field(
                controller: _capCtrl,
                hint: '20',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if ((int.tryParse(v) ?? 0) <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Price (optional)', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 6),
              _field(
                controller: _priceCtrl,
                hint: '0.00',
                keyboardType: TextInputType.number,
                prefix: const Text('\$  ', style: TextStyle(color: Colors.black54)),
              ),
              const SizedBox(height: 12),

              Text('Required ranks', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 2),
              Text('Leave empty for all ranks', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _allRanks.map((rank) {
                  final sel = _ranks.contains(rank);
                  return GestureDetector(
                    onTap: () => setState(() => sel ? _ranks.remove(rank) : _ranks.add(rank)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFCC0000) : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rank,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000),
                    disabledBackgroundColor: const Color(0xFFCC0000).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                      : const Text('Create Event', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1)),
      ),
    );
  }

  Widget _drop<T>({required T value, required List<T> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xFFCC0000), width: 1)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
    );
  }
}
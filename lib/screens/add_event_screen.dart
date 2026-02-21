import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEventScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddEventScreen({super.key, required this.selectedDate});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // optional
  final _instructorController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxCapacityController = TextEditingController(text: "20");

  String _selectedRoom = "Room A";
  String _selectedType = "Class";
  List<String> _selectedRanks = [];
  List<String> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  final List<String> _rooms = ["Room A", "Room B", "Room C"];
  final List<String> _types = ["Class", "Workshop", "Tournament", "Event"];
  final List<String> _daysOfWeek = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  final List<String> _allRanks = [
    "White Belt",
    "Yellow Belt",
    "Green Belt",
    "Blue Belt",
    "Brown Belt",
    "Red Belt",
    "Black Belt",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _instructorController.dispose();
    _priceController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one day")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // use the selected date just for the date component, time comes from time pickers
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

      // validate end time is after start time
      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End time must be after start time")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("events").add({
        "name": _nameController.text.trim(), // optional
        "type": _selectedType,
        "startTime": Timestamp.fromDate(startDateTime),
        "endTime": Timestamp.fromDate(endDateTime),
        "instructor": _instructorController.text.trim(),
        "requiredRanks": _selectedRanks,
        "price": double.tryParse(_priceController.text) ?? 0.0,
        "room": _selectedRoom,
        "maxCapacity": int.tryParse(_maxCapacityController.text) ?? 20,
        "currentEnrollment": 0,
        "description": null,
        "requirements": null,
        "daysOfWeek": _selectedDays,
        "startHour": _startTime.hour,
        "startMinute": _startTime.minute,
        "endHour": _endTime.hour,
        "endMinute": _endTime.minute,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Class created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating class: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create new class"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // days of week selection
              const Text("Days of week", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFFF0000).withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // time selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Start time", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(_startTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("End time", style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(_endTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // class name (optional)
              const Text("Class name (optional)", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "eg. Advanced Sparring",
                ),
              ),
              const SizedBox(height: 20),

              // type dropdown
              const Text("Type", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 20),

              // instructor
              const Text("Instructor(s)", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _instructorController,
                decoration: const InputDecoration(
                  hintText: "eg. SBN Lisa",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter instructor name(s)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // room dropdown
              const Text("Room", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRoom,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: _rooms.map((room) {
                  return DropdownMenuItem(value: room, child: Text(room));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRoom = value!);
                },
              ),
              const SizedBox(height: 20),

              // required ranks
              const Text("Required ranks (leave empty for all ranks)",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allRanks.map((rank) {
                  final isSelected = _selectedRanks.contains(rank);
                  return FilterChip(
                    label: Text(rank),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRanks.add(rank);
                        } else {
                          _selectedRanks.remove(rank);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFFF0000).withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // max capacity
              const Text("Max capacity", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _maxCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "20",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter max capacity";
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return "Please enter a valid number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // price
              const Text("price (optional)", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "0.00",
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 32),

              // create button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createEvent,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text("Create Class"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
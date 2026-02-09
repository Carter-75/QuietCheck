import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/data_service.dart';

class GoalCreationModalWidget extends StatefulWidget {
  final VoidCallback onGoalCreated;

  const GoalCreationModalWidget({super.key, required this.onGoalCreated});

  @override
  State<GoalCreationModalWidget> createState() =>
      _GoalCreationModalWidgetState();
}

class _GoalCreationModalWidgetState extends State<GoalCreationModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController(text: '7');

  String _selectedCategory = 'stress_reduction';
  String _selectedUnit = 'sessions';
  int _selectedWeeks = 2;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _templates = [
    {
      'category': 'stress_reduction',
      'title': 'Daily Stress Relief',
      'description': 'Practice stress reduction techniques daily',
      'icon': Icons.spa,
      'unit': 'sessions',
    },
    {
      'category': 'sleep_improvement',
      'title': 'Better Sleep Routine',
      'description': 'Improve sleep quality and duration',
      'icon': Icons.bedtime,
      'unit': 'nights',
    },
    {
      'category': 'mindfulness_practice',
      'title': 'Mindfulness Meditation',
      'description': 'Practice mindfulness and meditation',
      'icon': Icons.self_improvement,
      'unit': 'sessions',
    },
    {
      'category': 'work_life_balance',
      'title': 'Work-Life Balance',
      'description': 'Set boundaries and manage time effectively',
      'icon': Icons.balance,
      'unit': 'days',
    },
    {
      'category': 'physical_activity',
      'title': 'Physical Activity',
      'description': 'Regular exercise and movement',
      'icon': Icons.directions_run,
      'unit': 'workouts',
    },
    {
      'category': 'social_connection',
      'title': 'Social Connection',
      'description': 'Build supportive relationships',
      'icon': Icons.people,
      'unit': 'interactions',
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  void _selectTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedCategory = template['category'];
      _titleController.text = template['title'];
      _descriptionController.text = template['description'];
      _selectedUnit = template['unit'];
    });
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final targetDate = DateTime.now().add(Duration(days: _selectedWeeks * 7));
      await DataService.instance.createWellnessGoal(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        category: _selectedCategory,
        targetValue: int.parse(_targetValueController.text),
        unit: _selectedUnit,
        targetDate: targetDate,
      );

      widget.onGoalCreated();
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create goal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Wellness Goal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Templates
                Text(
                  'Choose a template',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                SizedBox(
                  height: 12.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      final isSelected =
                          _selectedCategory == template['category'];

                      return GestureDetector(
                        onTap: () => _selectTemplate(template),
                        child: Container(
                          width: 25.w,
                          margin: EdgeInsets.only(right: 2.w),
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                template['icon'],
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 28,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                template['title'].split(' ')[0],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 3.h),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal title';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 2.h),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                SizedBox(height: 2.h),

                // Target value and unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _targetValueController,
                        decoration: const InputDecoration(
                          labelText: 'Target',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'sessions',
                                  'days',
                                  'nights',
                                  'workouts',
                                  'interactions',
                                ]
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedUnit = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Timeframe
                Text(
                  'Timeframe: $_selectedWeeks weeks',
                  style: theme.textTheme.bodyMedium,
                ),
                Slider(
                  value: _selectedWeeks.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$_selectedWeeks weeks',
                  onChanged: (value) {
                    setState(() => _selectedWeeks = value.toInt());
                  },
                ),

                SizedBox(height: 2.h),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createGoal,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Goal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

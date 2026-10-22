import 'package:flutter/material.dart';
import '../models/task.dart';
import 'add_task_sheet.dart';

class AddTaskScreen extends StatelessWidget {
  final Task? taskToEdit;

  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AddTaskSheet(
          taskToEdit: taskToEdit,
          onSave: (task) {
            // Task is popped with result from AddTaskSheet
          },
        ),
      ),
    );
  }
}

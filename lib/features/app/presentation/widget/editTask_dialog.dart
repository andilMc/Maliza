import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:maliza/features/app/provider/task_provider.dart';

class EditTaskDialog extends StatefulWidget {
  final TaskProvider taskProvider;
  final FCalendarController dateController;
  final FTimePickerController timeController;
  final VoidCallback onCancel;
  final Function(Todo) onUpdate;
  final Future<void> Function({
    required TextEditingController dateTimeController,
    required TextEditingController taskController,
    required TaskProvider taskProvider,
  })
  onSelectDateTime;

  EditTaskDialog({
    required this.taskProvider,
    required this.dateController,
    required this.timeController,
    required this.onCancel,
    required this.onUpdate,
    required this.onSelectDateTime,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _taskController;
  late final TextEditingController _dateTimeController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(
      text: widget.taskProvider.updatingTodo.todo,
    );
    _dateTimeController = TextEditingController(
      text: widget.taskProvider.updatingTodo.date,
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    if (mounted) {
      widget.taskProvider.isFormValid =
          _taskController.text.trim().isNotEmpty &&
          _dateTimeController.text.trim().isNotEmpty;
    }
  }

  void _handleUpdate() {
    final updatedTodo = Todo(
      id: widget.taskProvider.updatingTodo.id,
      todo: _taskController.text.trim(),
      date: _dateTimeController.text,
      isCompleted: widget.taskProvider.updatingTodo.isCompleted,
      userId: widget.taskProvider.updatingTodo.userId,
    );
    widget.onUpdate(updatedTodo);
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      title: const Text('Modifier la tâche'),
      direction: Axis.horizontal,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            FTextField(
              controller: _taskController,
              label: const Row(
                spacing: 10,
                children: [
                  Icon(FIcons.clipboard, size: 16, color: Colors.black38),
                  Text("Titre de la tâche *"),
                ],
              ),
              hint: 'Ex: Faire les courses',
              maxLines: 3,
              enabled: !widget.taskProvider.isSubmitLoading,
              onChange: (_) => _updateFormValidity(),
            ),
            const SizedBox(height: 16),
            FTextField(
              controller: _dateTimeController,
              label: const Row(
                spacing: 10,
                children: [
                  Icon(FIcons.calendar, size: 16, color: Colors.black38),
                  Text("Date et Heure *"),
                ],
              ),
              hint: 'Sélectionnez une date et heure',
              readOnly: true,
              enabled: !widget.taskProvider.isSubmitLoading,
              onTap: () => widget.onSelectDateTime(
                dateTimeController: _dateTimeController,
                taskController: _taskController,
                taskProvider: widget.taskProvider,
              ),
              onChange: (_) => _updateFormValidity(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: widget.taskProvider.isSubmitLoading ? null : widget.onCancel,
          child: const Text('Annuler'),
        ),
        FButton(
          onPress:
              widget.taskProvider.isSubmitLoading ||
                  !widget.taskProvider.isFormValid
              ? null
              : _handleUpdate,
          prefix: widget.taskProvider.isSubmitLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  FIcons.save,
                  color: widget.taskProvider.isFormValid
                      ? Colors.white
                      : Colors.grey,
                ),
          child: Text(
            widget.taskProvider.isSubmitLoading
                ? 'Modification...'
                : 'Modifier',
            style: TextStyle(
              color: widget.taskProvider.isFormValid
                  ? Colors.white
                  : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

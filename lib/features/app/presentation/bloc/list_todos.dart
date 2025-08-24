import 'dart:async';

import 'package:maliza/core/models/todo.dart';
import 'package:maliza/features/app/presentation/widget/editTask_dialog.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ListTodos extends StatefulWidget {
  final List<Todo> todos;
  final TaskProvider taskProvider;
  final List<bool> checked;

  const ListTodos({
    super.key,
    required this.todos,
    required this.checked,
    required this.taskProvider,
  });

  @override
  State<ListTodos> createState() => _ListTodosState();
}

class _ListTodosState extends State<ListTodos> with TickerProviderStateMixin {
  static const String _dateFormat = "yyyy-M-d H:mm";
  static const Duration _navigationDelay = Duration(milliseconds: 100);

  late final SlidableController _slidableController;
  late final DateFormat _dateFormatter;
  late final DateFormat _inputFormat;

  FCalendarController? _dateController;
  FTimePickerController? _timeController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    _initializeDateFormatters();
  }

  void _initializeDateFormatters() {
    try {
      _dateFormatter = DateFormat('d MMMM yyyy à H:mm', 'fr_FR');
    } catch (e) {
      _dateFormatter = DateFormat('d MMMM yyyy at H:mm');
    }
    _inputFormat = DateFormat(_dateFormat);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _slidableController.dispose();
    _dateController?.dispose();
    _timeController?.dispose();
    super.dispose();
  }

  // Méthodes utilitaires optimisées
  bool get _hasDataInconsistency =>
      widget.todos.length != widget.checked.length;

  Icon _getTaskIcon(int index, Todo task) {
    if (index < 0 || index >= widget.checked.length) {
      return const Icon(FIcons.notebookPen, color: Colors.blue);
    }

    final isChecked = widget.checked[index];
    if (isChecked) {
      return const Icon(FIcons.checkCheck, color: Colors.green);
    }

    try {
      final taskDate = _inputFormat.parse(task.date);
      if (taskDate.isBefore(DateTime.now())) {
        return const Icon(FIcons.circleAlert, color: Colors.red);
      }
    } catch (e) {
      debugPrint('Erreur parsing date pour ${task.id}: ${task.date}');
    }

    return const Icon(FIcons.notebookPen, color: Colors.blue);
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = _inputFormat.parse(dateString);
      return _dateFormatter.format(dateTime);
    } catch (e) {
      debugPrint('Erreur formatage date: $dateString');
      return 'Date invalide';
    }
  }

  // Gestion des actions utilisateur
  Future<void> _handleTaskToggle(int index) async {
    if (!_isValidIndex(index)) return;
    debugPrint("============$index==============");
    try {
      await HapticFeedback.lightImpact();
      await widget.taskProvider.check(index);
    } catch (e) {
      debugPrint('Erreur toggle tâche: $e');
      if (mounted) {
        _showErrorToast('Erreur lors de la mise à jour de la tâche');
      }
    }
  }

  Future<void> _handleTaskDeletion(int index) async {
    if (!_isValidIndex(index)) return;

    final todo = widget.todos[index];
    final confirmed = await _showDeleteConfirmation(todo);

    if (confirmed == true && mounted) {
      try {
        final success = await widget.taskProvider.deleteTask(todo.id!);

        if (mounted) {
          if (success) {
            await HapticFeedback.mediumImpact();
            _showSuccessToast('Tâche supprimée avec succès');
          } else {
            _showErrorToast('Impossible de supprimer la tâche');
          }
        }
      } catch (e) {
        debugPrint('Erreur suppression: $e');
        if (mounted) {
          _showErrorToast("Erreur lors de la suppression de la tâche");
        }
      }
    }
  }

  bool _isValidIndex(int index) => index >= 0 && index < widget.todos.length;

  // Dialogs et UI
  Future<bool?> _showDeleteConfirmation(Todo todo) {
    return showFDialog<bool>(
      context: context,
      builder: (dialogContext, _, _) => FDialog(
        direction: Axis.horizontal,
        title: const Text('Supprimer la tâche'),
        body: Text('Êtes-vous sûr de vouloir supprimer "${todo.todo}" ?'),
        actions: [
          FButton(
            style: FButtonStyle.ghost(),
            onPress: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FButton(
            style: FButtonStyle.destructive(),
            onPress: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog() {
    if (!mounted) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.isFormValid = true;

    _initializeEditControllers(taskProvider);

    showFDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, _) => Consumer<TaskProvider>(
        builder: (context, provider, child) => EditTaskDialog(
          taskProvider: provider,
          dateController: _dateController!,
          timeController: _timeController!,
          onCancel: () => _cancelEdit(provider, dialogContext),
          onUpdate: (todo) => _handleUpdate(provider, dialogContext, todo),
          onSelectDateTime: _selectDateTime,
        ),
      ),
    );
  }

  void _initializeEditControllers(TaskProvider taskProvider) {
    DateTime initialDate = DateTime.now();
    FTime initialTime = FTime.now();

    try {
      initialDate = _inputFormat.parse(taskProvider.updatingTodo.date);
      initialTime = FTime(initialDate.hour, initialDate.minute);
    } catch (e) {
      debugPrint('Erreur parsing date: ${taskProvider.updatingTodo.date}');
    }

    _dateController = FCalendarController.date(initialSelection: initialDate);
    _timeController = FTimePickerController(initial: initialTime);
  }

  Future<void> _selectDateTime({
    required TextEditingController dateTimeController,
    required TextEditingController taskController,
    required TaskProvider taskProvider,
  }) async {
    if (!mounted) return;

    try {
      final selectedDate = await _selectDate();
      if (!mounted || selectedDate == null) return;

      await Future.delayed(_navigationDelay);
      if (!mounted) return;

      final selectedTime = await _selectTime();
      if (!mounted || selectedTime == null) return;

      _updateDateTime(
        selectedDate,
        selectedTime,
        dateTimeController,
        taskController,
        taskProvider,
      );
    } catch (e) {
      debugPrint('Erreur sélection date/heure: $e');
      if (mounted) {
        _showErrorToast('Erreur lors de la sélection de la date/heure');
      }
    }
  }

  Future<DateTime?> _selectDate() {
    return showFDialog<DateTime>(
      context: context,
      builder: (context, _, __) => FDialog(
        title: const Text('Sélectionnez une date'),
        body: SizedBox(
          height: 400,
          child: FCalendar(
            controller: _dateController!,
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 730)),
            onPress: (date) => Navigator.of(context).pop(date),
          ),
        ),
        actions: [
          FButton(
            style: FButtonStyle.ghost(),
            onPress: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<TimeOfDay?> _selectTime() {
    return showFDialog<TimeOfDay>(
      context: context,
      builder: (context, _, __) => FDialog(
        title: const Text('Sélectionnez une heure'),
        body: SizedBox(
          height: 300,
          width: 300,
          child: FTimePicker(hour24: true, controller: _timeController!),
        ),
        actions: [
          FButton(
            style: FButtonStyle.ghost(),
            onPress: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.red)),
          ),
          FButton(
            style: FButtonStyle.primary(),
            onPress: () {
              final time = TimeOfDay(
                hour: _timeController!.value.hour,
                minute: _timeController!.value.minute,
              );
              Navigator.of(context).pop(time);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _updateDateTime(
    DateTime date,
    TimeOfDay time,
    TextEditingController dateTimeController,
    TextEditingController taskController,
    TaskProvider taskProvider,
  ) {
    final finalDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final formattedDateTime = _inputFormat.format(finalDateTime);
    dateTimeController.text = formattedDateTime;

    if (mounted) {
      taskProvider.isFormValid =
          taskController.text.trim().isNotEmpty &&
          dateTimeController.text.trim().isNotEmpty;
    }
  }

  Future<void> _handleUpdate(
    TaskProvider taskProvider,
    BuildContext dialogContext,
    Todo updatedTodo,
  ) async {
    if (!mounted || !taskProvider.isFormValid) {
      _showErrorToast('Veuillez remplir tous les champs obligatoires');
      return;
    }

    try {
      final success = await taskProvider.updateTask(updatedTodo);

      if (!mounted) return;

      if (success) {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSuccessToast(
              taskProvider.successMessage.isNotEmpty
                  ? taskProvider.successMessage
                  : 'Tâche mise à jour avec succès',
            );
          }
        });

        _resetUpdatingTodo(taskProvider);
      } else {
        _showErrorToast(
          taskProvider.errorMessage.isNotEmpty
              ? taskProvider.errorMessage
              : 'Erreur lors de la mise à jour de la tâche',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Erreur technique lors de la mise à jour');
      }
    }
  }

  void _cancelEdit(TaskProvider taskProvider, BuildContext dialogContext) {
    _resetUpdatingTodo(taskProvider);
    Navigator.of(dialogContext).pop();
  }

  void _resetUpdatingTodo(TaskProvider taskProvider) {
    taskProvider.updatingTodo = Todo(todo: '', date: '', isCompleted: false);
  }

  // Messages toast
  void _showErrorToast(String message) {
    _showToast(message, true);
  }

  void _showSuccessToast(String message) {
    _showToast(message, false);
  }

  void _showToast(String message, bool isError) {
    if (!mounted) return;

    showFToast(
      alignment: FToastAlignment.topCenter,
      context: context,
      icon: Icon(
        isError ? FIcons.triangleAlert : FIcons.checkCheck,
        color: isError ? Colors.red : Colors.green,
        size: 20,
      ),
      title: Text(isError ? "Erreur" : "Succès"),
      description: SizedBox(width: double.maxFinite, child: Text(message)),
    );
  }

  // Widgets d'état
  Widget _buildDataInconsistencyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FIcons.triangleAlert, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Erreur de synchronisation des données',
            style: TextStyle(fontSize: 16, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Todos: ${widget.todos.length}, États: ${widget.checked.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.taskProvider.getTodos,
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FIcons.clipboard, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text(
            'Aucune tâche',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez votre première tâche !',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(int index) {
    final task = widget.todos[index];
    final isChecked = index < widget.checked.length
        ? widget.checked[index]
        : false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Slidable(
        key: ValueKey('${task.id}-$index-${task.isCompleted}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.6,
          children: [
            Consumer<TaskProvider>(
              builder: (context, taskProvider, _) => SlidableAction(
                onPressed: (_) {
                  taskProvider.updatingTodo = task;
                  _showEditTaskDialog();
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: FIcons.notebookPen,
                label: 'Éditer',
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _handleTaskDeletion(index),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: FIcons.trash,
              label: 'Supprimer',
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        child: FTile(
          onPress: () => _handleTaskToggle(index),
          prefix: _getTaskIcon(index, task),
          suffix: FCheckbox(
            value: isChecked,
            onChange: (_) => _handleTaskToggle(index),
          ),
          title: Text(
            task.todo,
            style: TextStyle(
              decoration: isChecked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: isChecked ? Colors.grey : null,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(task.date),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasDataInconsistency) {
      debugPrint(
        'Incohérence: todos=${widget.todos.length}, checked=${widget.checked.length}',
      );
      return _buildDataInconsistencyView();
    }

    if (widget.todos.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: widget.todos.length,
      itemBuilder: (context, index) {
        if (index >= widget.todos.length) {
          return const SizedBox.shrink();
        }
        return _buildTaskItem(index);
      },
    );
  }
}

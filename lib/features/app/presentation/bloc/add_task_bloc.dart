import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class AddTaskBloc extends StatefulWidget {
  const AddTaskBloc({super.key});

  @override
  State<AddTaskBloc> createState() => _AddTaskBlocState();
}

class _AddTaskBlocState extends State<AddTaskBloc>
    with TickerProviderStateMixin {
  late final FCalendarController _dateController;
  late final FTimePickerController _timeController;
  late final TextEditingController _taskController;
  late final TextEditingController _dateTimeController;

  @override
  void initState() {
    super.initState();
    _dateController = FCalendarController.date(
      initialSelection: DateTime.now(),
    );
    _timeController = FTimePickerController(initial: FTime.now());
    _taskController = TextEditingController();
    _dateTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _taskController.dispose();
    _dateTimeController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(TaskProvider taskProvider) async {
    if (!taskProvider.isFormValid) {
      _showMessage(
        message: 'Veuillez remplir tous les champs obligatoires',
        isError: true,
      );
      return;
    }

    try {
      final userId = await AccountCache.getCurrentAccountId();
      if (userId == null) {
        _showMessage(
          message: 'Erreur d\'authentification - Reconnectez-vous',
          isError: true,
        );
        return;
      }

      Todo todo = Todo(
        todo: _taskController.text,
        date: _dateTimeController.text,
        isCompleted: false,
        userId: userId,
      );

      final success = await taskProvider.insertTask(todo);

      if (mounted) {
        if (success) {
          _showMessage(
            message: taskProvider.successMessage.isNotEmpty
                ? taskProvider.successMessage
                : 'Tâche créée avec succès',
            isError: false,
          );
          // Fermer le dialog après succès
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        } else {
          _showMessage(
            message: taskProvider.errorMessage.isNotEmpty
                ? taskProvider.errorMessage
                : 'Erreur lors de la création de la tâche',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          message: 'Erreur technique lors de la création',
          isError: true,
        );
      }
    }
  }

  void _showMessage({required String message, required bool isError}) {
    if (!mounted) return;

    // Essayer d'abord FToast, sinon utiliser SnackBar
    try {
      showFToast(
        alignment: FToastAlignment.topCenter,
        context: context,
        icon: Icon(
          isError ? FIcons.triangleAlert : FIcons.checkCheck,
          color: isError ? Colors.red : Colors.green,
          size: 20,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback vers SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetForm() {
    _taskController.clear();
    _dateTimeController.clear();
    _dateController.value = null;
    _timeController.value = FTime.now();
  }

  Future<void> _selectDateTime() async {
    DateTime? selectedDate;

    // Sélection de la date
    bool? dateOk = await showFDialog<bool>(
      context: context,
      builder: (dateContext, _, _) {
        return FDialog(
          title: const Text('Sélectionnez une date'),
          actions: [
            FButton(
              style: FButtonStyle.ghost(),
              onPress: () => Navigator.of(dateContext).pop(false),
              child: const Text('Annuler'),
            ),
          ],
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FCalendar(
                controller: _dateController,
                start: DateTime.now(),
                end: DateTime.now().add(const Duration(days: 365 * 2)),
                onPress: (date) {
                  selectedDate = date;
                  Navigator.of(dateContext).pop(true);
                },
              ),
            ],
          ),
        );
      },
    );

    if (dateOk != true || selectedDate == null) return;

    // Sélection de l'heure
    TimeOfDay? selectedTime = await showFDialog<TimeOfDay>(
      context: context,
      builder: (timeContext, _, _) {
        return FDialog(
          title: const Text('Sélectionnez une heure'),
          direction: Axis.horizontal,
          body: SizedBox(
            height: 300,
            child: FTimePicker(
              hour24: true,
              controller: _timeController,
              onChange: (time) {
                debugPrint('Heure sélectionnée: $time');
              },
            ),
          ),
          actions: [
            FButton(
              style: FButtonStyle.ghost(),
              onPress: () => Navigator.of(timeContext).pop(null),
              child: const Text('Annuler', style: TextStyle(color: Colors.red)),
            ),
            FButton(
              style: FButtonStyle.primary(),
              onPress: () {
                TimeOfDay time = TimeOfDay(
                  hour: _timeController.value.hour,
                  minute: _timeController.value.minute,
                );
                Navigator.of(timeContext).pop(time);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    // Combiner date et heure
    if (selectedTime != null) {
      DateTime finalDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      _dateTimeController.text =
          "${finalDateTime.year}-${finalDateTime.month}-${finalDateTime.day} ${finalDateTime.hour}:${finalDateTime.minute.toString().padLeft(2, '0')}";

      // Valider le formulaire
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.isFormValid =
          _taskController.text.isNotEmpty &&
          _dateTimeController.text.isNotEmpty;
    }
  }

  void _showAddTaskDialog() {
    _resetForm();

    showFDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, _) => Consumer<TaskProvider>(
        builder: (consumerContext, taskProvider, child) {
          return FDialog(
            title: const Text('Créer une nouvelle tâche'),
            direction: Axis.horizontal,
            body: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  FTextField(
                    controller: _taskController,
                    label: Row(
                      spacing: 10,
                      children: [
                        Icon(FIcons.clipboard, size: 16, color: Colors.black38),
                        const Text("Titre de la tâche *"),
                      ],
                    ),
                    hint: 'Ex: Faire les courses',
                    maxLines: 3,
                    enabled: !taskProvider.isSubmitLoading,
                    onChange: (value) {
                      taskProvider.isFormValid =
                          value.isNotEmpty &&
                          _dateTimeController.text.isNotEmpty;
                    },
                  ),
                  const SizedBox(height: 16),
                  FTextField(
                    controller: _dateTimeController,
                    label: Row(
                      spacing: 10,
                      children: [
                        Icon(FIcons.calendar, size: 16, color: Colors.black38),
                        const Text("Date et Heure *"),
                      ],
                    ),
                    hint: 'Sélectionnez une date et heure',
                    readOnly: true,
                    enabled: !taskProvider.isSubmitLoading,
                    onTap: _selectDateTime,
                    onChange: (value) {
                      taskProvider.isFormValid =
                          value.isNotEmpty && _taskController.text.isNotEmpty;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: taskProvider.isSubmitLoading
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              FButton(
                onPress:
                    taskProvider.isSubmitLoading || !taskProvider.isFormValid
                    ? null
                    : () async {
                        await _handleSubmit(taskProvider);
                      },
                prefix: taskProvider.isSubmitLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        FIcons.save,
                        color: taskProvider.isFormValid
                            ? Colors.white
                            : Colors.grey,
                      ),
                child: Text(
                  taskProvider.isSubmitLoading ? 'Création...' : 'Créer',
                  style: TextStyle(
                    color: taskProvider.isFormValid
                        ? Colors.white
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FButton(
      onPress: _showAddTaskDialog,
      child: const Icon(FIcons.plus, size: 24),
    );
  }
}

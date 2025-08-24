import 'package:maliza/core/models/task_filter_type.dart';
import 'package:maliza/features/app/presentation/bloc/list_todos.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class TaskListWidget extends StatefulWidget {
  final TaskFilterType filterType;

  const TaskListWidget({super.key, this.filterType = TaskFilterType.all});

  @override
  _TaskListWidgetState createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget>
    with TickerProviderStateMixin {
  List<Todo> _getFilteredTodos(TaskProvider taskProvider) {
    switch (widget.filterType) {
      case TaskFilterType.all:
        return taskProvider.todos;
      case TaskFilterType.completed:
        return taskProvider.completed;
      case TaskFilterType.overdue:
        return taskProvider.overdue;
    }
  }

  List<bool> _getFilteredCheckedStates(
    TaskProvider taskProvider,
    List<Todo> filteredTodos,
  ) {
    // Créer une liste de vérification basée sur les tâches filtrées
    List<bool> filteredChecked = [];

    for (Todo todo in filteredTodos) {
      // Trouver l'index de cette tâche dans la liste principale
      int originalIndex = taskProvider.todos.indexWhere((t) => t.id == todo.id);
      if (originalIndex != -1 &&
          originalIndex < taskProvider.todosChecked.length) {
        filteredChecked.add(taskProvider.todosChecked[originalIndex]);
      } else {
        filteredChecked.add(todo.isCompleted);
      }
    }

    return filteredChecked;
  }

  String _getEmptyMessage() {
    switch (widget.filterType) {
      case TaskFilterType.all:
        return "Aucune tâche à faire";
      case TaskFilterType.completed:
        return "Aucune tâche terminée";
      case TaskFilterType.overdue:
        return "Aucune tâche en retard";
    }
  }

  String _getEmptySubtitle() {
    switch (widget.filterType) {
      case TaskFilterType.all:
        return "Appuyez sur + pour créer votre première tâche";
      case TaskFilterType.completed:
        return "Terminez vos tâches pour les voir ici";
      case TaskFilterType.overdue:
        return "Pas de retard, c'est parfait !";
    }
  }

  IconData _getEmptyIcon() {
    switch (widget.filterType) {
      case TaskFilterType.all:
        return FIcons.clipboardPenLine;
      case TaskFilterType.completed:
        return FIcons.clipboardCheck;
      case TaskFilterType.overdue:
        return FIcons.clockAlert;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                showFToast(
                  alignment: FToastAlignment.topCenter,
                  icon: Icon(FIcons.triangleAlert, color: Colors.red),
                  context: context,
                  title: Text("Erreur"),
                  description: Text(taskProvider.errorMessage),
                  onDismiss: () => taskProvider.clearMessages(),
                );
              }
            });
          }

          if (taskProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FProgress.circularIcon(),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des tâches...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ).animate().fade(duration: 1.seconds);
          }

          // Obtenir les tâches filtrées
          final filteredTodos = _getFilteredTodos(taskProvider);
          final filteredChecked = _getFilteredCheckedStates(
            taskProvider,
            filteredTodos,
          );

          if (filteredTodos.isNotEmpty) {
            return RefreshIndicator(
              backgroundColor: Colors.white,
              color: Colors.black,
              edgeOffset: 10,
              onRefresh: () async {
                HapticFeedback.vibrate();
                await taskProvider.getTodos();
              },
              child: FilteredListTodos(
                todos: filteredTodos,
                originalTodos: taskProvider.todos,
                taskProvider: taskProvider,
                checked: filteredChecked,
              ),
            );
          }

          // État vide avec message personnalisé
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getEmptyIcon(), size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getEmptySubtitle(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                if (widget.filterType == TaskFilterType.all) ...[],
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget séparé pour gérer la liste filtrée
class FilteredListTodos extends StatefulWidget {
  final List<Todo> todos;
  final List<Todo> originalTodos;
  final TaskProvider taskProvider;
  final List<bool> checked;

  const FilteredListTodos({
    super.key,
    required this.todos,
    required this.originalTodos,
    required this.checked,
    required this.taskProvider,
  });

  @override
  State<FilteredListTodos> createState() => _FilteredListTodosState();
}

class _FilteredListTodosState extends State<FilteredListTodos> {
  @override
  Widget build(BuildContext context) {
    return ListTodos(
      todos: widget.todos,
      taskProvider: widget.taskProvider,
      checked: widget.checked,
    );
  }
}

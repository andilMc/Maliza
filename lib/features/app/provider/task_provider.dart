import 'package:flutter/material.dart';
import 'package:maliza/core/data/database_helper.dart';
import 'package:maliza/core/models/todo.dart';
import 'package:intl/intl.dart';

class TaskProvider extends ChangeNotifier {
  final Databasehelper _databaseHelper = Databasehelper();

  // États de chargement
  bool _isLoading = false;
  bool _isSubmitLoading = false;
  bool _hasError = false;
  bool _isSuccess = false;
  bool _isFormValid = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Données
  List<Todo> _todos = [];
  List<bool> _todosChecked = [];

  List<Todo> overdue = [];
  List<Todo> completed = [];
  List<Todo> _originalTodos = [];

  Todo updatingTodo = Todo(todo: '', date: '', isCompleted: false);
  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitLoading => _isSubmitLoading;
  bool get hasError => _hasError;
  bool get isSuccess => _isSuccess;
  bool get isFormValid => _isFormValid;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  List<Todo> get todos => List.unmodifiable(_todos);
  List<bool> get todosChecked => List.unmodifiable(_todosChecked);

  set isFormValid(bool value) {
    if (_isFormValid != value) {
      _isFormValid = value;
      notifyListeners();
    }
  }

  void clearAllDataForLogout() {
    updatingTodo = Todo(todo: '', date: '', isCompleted: false);
    _isLoading = false;
    _todos = [];
    _todosChecked = [];
    _originalTodos = [];
    overdue = [];
    completed = [];
    notifyListeners();
  }

  void setUpdatingTodo(Todo todo) {
    updatingTodo = todo;
    notifyListeners();
  }

  void _setSubmitState({
    bool? loading,
    bool? success,
    String? successMsg,
    bool? error,
    String? errorMsg,
  }) {
    if (loading != null) _isSubmitLoading = loading;
    if (success != null) _isSuccess = success;
    if (successMsg != null) _successMessage = successMsg;
    if (error != null) _hasError = error;
    if (errorMsg != null) _errorMessage = errorMsg;
    notifyListeners();
  }

  void _setLoadingState(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  Future<bool> _handleTaskOperation(
    Future<int> Function() operation,
    String successMsg,
    String errorMsg,
  ) async {
    try {
      _setSubmitState(loading: true, success: false, error: false);

      final result = await operation();

      if (result <= 0) {
        _setSubmitState(
          loading: false,
          error: true,
          errorMsg: errorMsg,
          success: false,
          successMsg: '',
        );
        return false;
      } else {
        _setSubmitState(
          loading: false,
          success: true,
          successMsg: successMsg,
          error: false,
          errorMsg: '',
        );
        return true;
      }
    } catch (e) {
      _setSubmitState(
        loading: false,
        error: true,
        errorMsg: 'Erreur technique: ${e.toString()}',
        success: false,
        successMsg: '',
      );
      return false;
    } finally {
      _isSubmitLoading = false;
      notifyListeners();
    }
  }

  Future<bool> insertTask(Todo todo) async {
    if (todo.todo.trim().isEmpty) {
      _setSubmitState(
        error: true,
        errorMsg: 'Le titre de la tâche ne peut pas être vide',
      );
      return false;
    }

    final bool success = await _handleTaskOperation(
      () => _databaseHelper.insertTodo(todo),
      'Tâche ajoutée avec succès',
      'Impossible d\'ajouter la tâche',
    );

    if (success) {
      await _refreshTodos(); // Recharger et trier automatiquement
    }

    return success;
  }

  Future<bool> updateTask(Todo todo) async {
    if (todo.todo.trim().isEmpty) {
      _setSubmitState(
        error: true,
        errorMsg: 'Le titre de la tâche ne peut pas être vide',
      );
      return false;
    }

    final success = await _handleTaskOperation(
      () => _databaseHelper.updateTodo(todo),
      'Tâche mise à jour avec succès',
      'Impossible de mettre à jour la tâche',
    );

    if (success) {
      await _refreshTodos(); // Recharger après succès
    }

    return success;
  }

  Future<bool> deleteTask(int todoId) async {
    final success = await _handleTaskOperation(
      () => _databaseHelper.deleteTodo(todoId),
      'Tâche supprimée avec succès',
      'Impossible de supprimer la tâche',
    );

    if (success) {
      await _refreshTodos(); // Recharger après succès
    }

    return success;
  }

  void _updateFilteredLists() {
    // Mettre à jour la liste des tâches terminées
    completed = _todos.where((todo) => todo.isCompleted).toList();

    // Mettre à jour la liste des tâches en retard
    overdue = _todos.where((todo) {
      if (todo.isCompleted) return false;
      try {
        final DateFormat format = DateFormat("yyyy-M-d H:mm");
        final date = format.parse(todo.date);
        return date.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> getTodos() async {
    _setLoadingState(true);

    try {
      await _refreshTodos();
    } catch (e) {
      _setSubmitState(
        error: true,
        errorMsg: 'Impossible de charger les tâches',
      );
      debugPrint('Erreur lors du chargement des todos: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> check(int index) async {
    if (index < 0 || index >= _todos.length) {
      debugPrint('Index invalide pour check: $index');
      return;
    }

    // Sauvegarde de l'état original
    final originalTodo = _todos[index];
    final newCompletedState = !originalTodo.isCompleted;

    // Créer le nouveau todo
    final updatedTodo = Todo(
      id: originalTodo.id,
      todo: originalTodo.todo,
      isCompleted: newCompletedState,
      date: originalTodo.date,
      userId: originalTodo.userId,
    );

    try {
      _todosChecked[index] = updatedTodo.isCompleted;
      _todos[index] = updatedTodo;
      notifyListeners();
      // Mise à jour en base de données AVANT la mise à jour UI
      final result = await _databaseHelper.updateTodo(updatedTodo);

      if (result > 0) {
        // Succès : mettre à jour l'état local et re-trier
        await _refreshTodos(); // Cela va trier et synchroniser automatiquement
      } else {
        // Échec de la mise à jour en base
        _setSubmitState(
          error: true,
          errorMsg: 'Impossible de mettre à jour la tâche',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du check: $e');
      _setSubmitState(
        error: true,
        errorMsg: 'Erreur lors de la mise à jour de la tâche',
      );
    }
  }

  Future<void> search(String keyword) async {
    try {
      if (_originalTodos.isEmpty && _todos.isNotEmpty) {
        _originalTodos = List<Todo>.from(_todos);
      }

      if (keyword.trim().isEmpty) {
        if (_originalTodos.isNotEmpty) {
          _todos = List<Todo>.from(_originalTodos);
          _todosChecked = _todos.map((t) => t.isCompleted).toList();
          _sortTodos();
          _updateFilteredLists();
        }
      } else {
        final todosToSearch = _originalTodos.isNotEmpty
            ? _originalTodos
            : _todos;

        _todos = todosToSearch
            .where(
              (todo) => todo.todo.toLowerCase().contains(keyword.toLowerCase()),
            )
            .toList();

        _todosChecked = _todos.map((t) => t.isCompleted).toList();
        _sortTodos();
        _updateFilteredLists();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      _setSubmitState(error: true, errorMsg: 'Erreur lors de la recherche');
    }
  }

  void clearSearch() {
    if (_originalTodos.isNotEmpty) {
      _todos = List<Todo>.from(_originalTodos);
      _todosChecked = _todos.map((t) => t.isCompleted).toList();
      _sortTodos();
      _updateFilteredLists();
      notifyListeners();
    }
  }

  Future<void> _refreshTodos() async {
    try {
      final todos = await _databaseHelper.getAlltodo();
      _todos = List<Todo>.from(todos);
      _originalTodos = List<Todo>.from(_todos);
      _todosChecked = _todos.map((t) => t.isCompleted).toList();

      // Trier les todos
      _sortTodos();

      _todosChecked = _todos.map((t) => t.isCompleted).toList();

      // Mettre à jour les listes filtrées
      _updateFilteredLists();

      // Notifier les listeners après toutes les modifications
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du refresh des todos: $e');
      _setSubmitState(
        error: true,
        errorMsg: 'Erreur lors du chargement des données',
      );
    }
  }

  void _sortTodos() {
    if (_todos.isEmpty) return;

    try {
      final now = DateTime.now();
      final DateFormat format = DateFormat("yyyy-M-d H:mm");

      _todos.sort((a, b) {
        try {
          // Priorité 1: Les tâches non terminées avant les terminées
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }

          // Parsing des dates avec gestion d'erreur
          DateTime? dateA;
          DateTime? dateB;

          try {
            dateA = format.parse(a.date);
          } catch (e) {
            debugPrint('Date invalide pour tâche ${a.id}: ${a.date}');
          }

          try {
            dateB = format.parse(b.date);
          } catch (e) {
            debugPrint('Date invalide pour tâche ${b.id}: ${b.date}');
          }

          // Si une date est invalide, mettre l'élément à la fin
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          // Pour les tâches non terminées : trier par priorité temporelle
          if (!a.isCompleted && !b.isCompleted) {
            final isPastA = dateA.isBefore(now);
            final isPastB = dateB.isBefore(now);

            // Tâches en retard en premier
            if (isPastA && !isPastB) return -1;
            if (!isPastA && isPastB) return 1;

            // Si les deux sont en retard, les plus récentes d'abord
            if (isPastA && isPastB) return dateB.compareTo(dateA);

            // Si les deux sont futures, les plus proches d'abord
            return dateA.compareTo(dateB);
          }

          // Pour les tâches terminées : les plus récentes d'abord
          return dateB.compareTo(dateA);
        } catch (e) {
          debugPrint('Erreur lors de la comparaison: $e');
          return 0;
        }
      });
    } catch (e) {
      debugPrint('Erreur lors du tri des todos: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void clearMessages() {
    _hasError = false;
    _isSuccess = false;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }

  // Modifiez également votre méthode getStatistics() pour utiliser les listes mises à jour
  Map<String, int> getStatistics() {
    // S'assurer que les listes filtrées sont à jour
    _updateFilteredLists();

    final pending = _todos.length - completed.length;

    return {
      'total': _todos.length,
      'completed': completed.length,
      'pending': pending,
      'overdue': overdue.length,
    };
  }
}

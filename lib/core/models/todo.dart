class Todo {
  int? id;
  String todo;
  String date;
  bool isCompleted;
  int? userId;

  Todo({
    this.id,
    required this.todo,
    required this.date,
    required this.isCompleted,
    this.userId,
  });

  factory Todo.fromMap(Map<String, dynamic> json) {
    return Todo(
      id: json['todo_id'] as int?,
      todo: json['todo'] as String,
      date: json['date'] as String,
      isCompleted: (json['done'] == 1) ? true : false,
      userId: json['account_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    int done = isCompleted ? 1 : 0;
    return {
      'todo_id': id,
      'todo': todo,
      'date': date,
      'done': done,
      'account_id': userId,
    };
  }
}

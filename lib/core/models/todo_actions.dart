enum TodoActions {
  update('u'),
  delete('d'),
  insert('i');

  final String action;
  const TodoActions(this.action);
}

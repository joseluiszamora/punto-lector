part of 'books_bloc.dart';

abstract class BooksEvent extends Equatable {
  const BooksEvent();
  @override
  List<Object?> get props => [];
}

class BooksSearchRequested extends BooksEvent {
  final String? title;
  final String? author; // buscará contra autores M:N
  const BooksSearchRequested({this.title, this.author});
  @override
  List<Object?> get props => [title, author];
}

class BooksAdminListRequested extends BooksEvent {
  const BooksAdminListRequested();
}

class BookCreateRequested extends BooksEvent {
  final Book draft;
  const BookCreateRequested(this.draft);
  @override
  List<Object?> get props => [draft];
}

class BookUpdateRequested extends BooksEvent {
  final String id;
  final Book changes;
  const BookUpdateRequested(this.id, this.changes);
  @override
  List<Object?> get props => [id, changes];
}

class BookDeleteRequested extends BooksEvent {
  final String id;
  const BookDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

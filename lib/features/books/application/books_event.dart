part of 'books_bloc.dart';

abstract class BooksEvent extends Equatable {
  const BooksEvent();
  @override
  List<Object?> get props => [];
}

class BooksSearchRequested extends BooksEvent {
  final String? title;
  final String? author;
  const BooksSearchRequested({this.title, this.author});
  @override
  List<Object?> get props => [title, author];
}

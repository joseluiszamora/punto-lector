part of 'books_bloc.dart';

sealed class BooksState extends Equatable {
  const BooksState();
  const factory BooksState.initial() = BooksInitial;
  const factory BooksState.loading() = BooksLoading;
  const factory BooksState.loaded(List<Book> books) = BooksLoaded;
  const factory BooksState.error(String message) = BooksError;

  @override
  List<Object?> get props => [];
}

class BooksInitial extends BooksState {
  const BooksInitial();
}

class BooksLoading extends BooksState {
  const BooksLoading();
}

class BooksLoaded extends BooksState {
  final List<Book> books;
  const BooksLoaded(this.books);
  @override
  List<Object?> get props => [books];
}

class BooksError extends BooksState {
  final String message;
  const BooksError(this.message);
  @override
  List<Object?> get props => [message];
}

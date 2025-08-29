import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/books_repository.dart';
import '../../../data/models/book.dart';

part 'books_event.dart';
part 'books_state.dart';

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final IBooksRepository _repo;
  BooksBloc(this._repo) : super(const BooksState.initial()) {
    on<BooksSearchRequested>(_onSearch);
  }

  Future<void> _onSearch(
    BooksSearchRequested event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksState.loading());
    try {
      final results = await _repo.search(
        title: event.title,
        author: event.author,
      );
      emit(BooksState.loaded(results));
    } catch (e) {
      emit(BooksState.error(e.toString()));
    }
  }
}

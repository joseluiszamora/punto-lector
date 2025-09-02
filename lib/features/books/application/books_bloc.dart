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
    on<BooksAdminListRequested>(_onAdminList);
    on<BookCreateRequested>(_onCreate);
    on<BookUpdateRequested>(_onUpdate);
    on<BookDeleteRequested>(_onDelete);
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

  Future<void> _onAdminList(
    BooksAdminListRequested event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksState.loading());
    try {
      final results = await _repo.listAll();
      emit(BooksState.loaded(results));
    } catch (e) {
      emit(BooksState.error(e.toString()));
    }
  }

  Future<void> _onCreate(
    BookCreateRequested event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksState.operating());
    try {
      await _repo.create(event.draft);
      emit(const BooksState.operationSuccess());
      add(const BooksAdminListRequested());
    } catch (e) {
      emit(BooksState.error(e.toString()));
    }
  }

  Future<void> _onUpdate(
    BookUpdateRequested event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksState.operating());
    try {
      await _repo.update(event.id, event.changes);
      emit(const BooksState.operationSuccess());
      add(const BooksAdminListRequested());
    } catch (e) {
      emit(BooksState.error(e.toString()));
    }
  }

  Future<void> _onDelete(
    BookDeleteRequested event,
    Emitter<BooksState> emit,
  ) async {
    emit(const BooksState.operating());
    try {
      await _repo.delete(event.id);
      emit(const BooksState.operationSuccess());
      add(const BooksAdminListRequested());
    } catch (e) {
      emit(BooksState.error(e.toString()));
    }
  }
}

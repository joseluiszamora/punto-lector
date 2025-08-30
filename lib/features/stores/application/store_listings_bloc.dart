import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/store_listing.dart';
import '../../../data/repositories/listings_repository.dart';

part 'store_listings_event.dart';
part 'store_listings_state.dart';

class StoreListingsBloc extends Bloc<StoreListingsEvent, StoreListingsState> {
  final IListingsRepository _repo;
  final String storeId;
  StoreListingsBloc(this._repo, {required this.storeId})
    : super(const StoreListingsState.initial()) {
    on<StoreListingsRequested>(_onLoad);
    on<StoreListingAddRequested>(_onAdd);
    on<StoreListingRemoveRequested>(_onRemove);
  }

  Future<void> _onLoad(
    StoreListingsRequested event,
    Emitter<StoreListingsState> emit,
  ) async {
    emit(const StoreListingsState.loading());
    try {
      final items = await _repo.listByStore(storeId);
      emit(StoreListingsState.loaded(items));
    } catch (e) {
      emit(StoreListingsState.error(e.toString()));
    }
  }

  Future<void> _onAdd(
    StoreListingAddRequested event,
    Emitter<StoreListingsState> emit,
  ) async {
    try {
      final created = await _repo.add(
        storeId: storeId,
        bookId: event.bookId,
        price: event.price,
        currency: event.currency,
        stock: event.stock,
      );
      final current =
          state is StoreListingsLoaded
              ? (state as StoreListingsLoaded).items
              : <StoreListing>[];
      emit(StoreListingsState.loaded([created, ...current]));
    } catch (e) {
      emit(StoreListingsState.error(e.toString()));
    }
  }

  Future<void> _onRemove(
    StoreListingRemoveRequested event,
    Emitter<StoreListingsState> emit,
  ) async {
    try {
      await _repo.remove(event.id);
      final current =
          state is StoreListingsLoaded
              ? (state as StoreListingsLoaded).items
              : <StoreListing>[];
      emit(
        StoreListingsState.loaded(
          current.where((e) => e.id != event.id).toList(),
        ),
      );
    } catch (e) {
      emit(StoreListingsState.error(e.toString()));
    }
  }
}

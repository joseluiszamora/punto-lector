import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/store.dart';
import '../../../data/repositories/stores_repository.dart';

part 'stores_event.dart';
part 'stores_state.dart';

class StoresBloc extends Bloc<StoresEvent, StoresState> {
  final IStoresRepository _repo;
  final String ownerUid;
  StoresBloc(this._repo, {required this.ownerUid})
    : super(const StoresState.initial()) {
    on<StoresRequested>(_onLoad);
    on<StoreCreateRequested>(_onCreate);
    on<StoreUpdateRequested>(_onUpdate);
  }

  Future<void> _onLoad(StoresRequested event, Emitter<StoresState> emit) async {
    emit(const StoresState.loading());
    try {
      final list = await _repo.listMyStores(ownerUid);
      emit(StoresState.loaded(list));
    } catch (e) {
      emit(StoresState.error(e.toString()));
    }
  }

  Future<void> _onCreate(
    StoreCreateRequested event,
    Emitter<StoresState> emit,
  ) async {
    try {
      final created = await _repo.create(event.store);
      final current =
          state is StoresLoaded ? (state as StoresLoaded).stores : <Store>[];
      emit(StoresState.loaded([created, ...current]));
    } catch (e) {
      emit(StoresState.error(e.toString()));
    }
  }

  Future<void> _onUpdate(
    StoreUpdateRequested event,
    Emitter<StoresState> emit,
  ) async {
    try {
      final updated = await _repo.update(event.id, event.patch);
      final current =
          state is StoresLoaded ? (state as StoresLoaded).stores : <Store>[];
      final next =
          current.map((s) => s.id == updated.id ? updated : s).toList();
      emit(StoresState.loaded(next));
    } catch (e) {
      emit(StoresState.error(e.toString()));
    }
  }
}

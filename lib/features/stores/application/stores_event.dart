part of 'stores_bloc.dart';

abstract class StoresEvent extends Equatable {
  const StoresEvent();
  @override
  List<Object?> get props => [];
}

class StoresRequested extends StoresEvent {
  const StoresRequested();
}

class StoreCreateRequested extends StoresEvent {
  final Store store;
  const StoreCreateRequested(this.store);
  @override
  List<Object?> get props => [store];
}

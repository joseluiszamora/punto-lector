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

// Nuevo evento para actualizar una tienda existente
class StoreUpdateRequested extends StoresEvent {
  final String id;
  final Map<String, dynamic> patch;
  const StoreUpdateRequested(this.id, this.patch);
  @override
  List<Object?> get props => [id, patch];
}

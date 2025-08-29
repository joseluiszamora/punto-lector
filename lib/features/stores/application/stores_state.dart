part of 'stores_bloc.dart';

sealed class StoresState extends Equatable {
  const StoresState();
  const factory StoresState.initial() = StoresInitial;
  const factory StoresState.loading() = StoresLoading;
  const factory StoresState.loaded(List<Store> stores) = StoresLoaded;
  const factory StoresState.error(String message) = StoresError;

  @override
  List<Object?> get props => [];
}

class StoresInitial extends StoresState {
  const StoresInitial();
}

class StoresLoading extends StoresState {
  const StoresLoading();
}

class StoresLoaded extends StoresState {
  final List<Store> stores;
  const StoresLoaded(this.stores);
  @override
  List<Object?> get props => [stores];
}

class StoresError extends StoresState {
  final String message;
  const StoresError(this.message);
  @override
  List<Object?> get props => [message];
}

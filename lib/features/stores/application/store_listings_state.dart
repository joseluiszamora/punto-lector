part of 'store_listings_bloc.dart';

sealed class StoreListingsState extends Equatable {
  const StoreListingsState();
  const factory StoreListingsState.initial() = StoreListingsInitial;
  const factory StoreListingsState.loading() = StoreListingsLoading;
  const factory StoreListingsState.loaded(List<StoreListing> items) =
      StoreListingsLoaded;
  const factory StoreListingsState.error(String message) = StoreListingsError;

  @override
  List<Object?> get props => [];
}

class StoreListingsInitial extends StoreListingsState {
  const StoreListingsInitial();
}

class StoreListingsLoading extends StoreListingsState {
  const StoreListingsLoading();
}

class StoreListingsLoaded extends StoreListingsState {
  final List<StoreListing> items;
  const StoreListingsLoaded(this.items);
  @override
  List<Object?> get props => [items];
}

class StoreListingsError extends StoreListingsState {
  final String message;
  const StoreListingsError(this.message);
  @override
  List<Object?> get props => [message];
}

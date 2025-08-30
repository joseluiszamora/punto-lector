part of 'store_listings_bloc.dart';

abstract class StoreListingsEvent extends Equatable {
  const StoreListingsEvent();
  @override
  List<Object?> get props => [];
}

class StoreListingsRequested extends StoreListingsEvent {
  const StoreListingsRequested();
}

class StoreListingAddRequested extends StoreListingsEvent {
  final String bookId;
  final double price;
  final String currency;
  final int stock;
  const StoreListingAddRequested({
    required this.bookId,
    required this.price,
    this.currency = 'BOB',
    this.stock = 0,
  });
  @override
  List<Object?> get props => [bookId, price, currency, stock];
}

class StoreListingRemoveRequested extends StoreListingsEvent {
  final String id;
  const StoreListingRemoveRequested(this.id);
  @override
  List<Object?> get props => [id];
}

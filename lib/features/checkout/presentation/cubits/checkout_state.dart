import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout_contact_entity.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutContactStep extends CheckoutState {
  final CheckoutContactEntity contact;

  const CheckoutContactStep(this.contact);

  @override
  List<Object?> get props => [contact];
}

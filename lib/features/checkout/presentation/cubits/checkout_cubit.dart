import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../domain/entities/checkout_contact_entity.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(CheckoutInitial());

  void startCheckout() {
    emit(CheckoutContactStep(CheckoutContactEntity.empty()));
  }

  void updateContact(CheckoutContactEntity contact) {
    emit(CheckoutContactStep(contact));
  }

  void setOrderForSelf(String name, String address) {
    emit(CheckoutContactStep(CheckoutContactEntity(
      name: name,
      houseFlatBuilding: '',
      streetAreaColony: address,
      city: '',
      state: '',
      pincode: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: true,
    )));
  }

  void setOrderForSomeoneElse() {
    emit(CheckoutContactStep(const CheckoutContactEntity(
      name: '',
      houseFlatBuilding: '',
      streetAreaColony: '',
      city: '',
      state: '',
      pincode: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: false,
    )));
  }
}

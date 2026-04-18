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
      address: address,
      landmark: '',
      phoneNumber: '',
      isForSelf: true,
    )));
  }

  void setOrderForSomeoneElse() {
    emit(CheckoutContactStep(const CheckoutContactEntity(
      name: '',
      address: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: false,
    )));
  }
}

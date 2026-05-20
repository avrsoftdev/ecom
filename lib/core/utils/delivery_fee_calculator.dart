const double freeDeliveryMinimum = 150.0;
const double standardDeliveryFee = 30.0;

double calculateDeliveryFee(num subtotal) {
  return subtotal < freeDeliveryMinimum ? standardDeliveryFee : 0.0;
}

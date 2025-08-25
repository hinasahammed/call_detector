class CustomerStatusModel {
  CustomerStatusModel({
    this.isCustomer = false,
    this.billingName = "",
    this.customerCode = "",
  });
  final bool isCustomer;
  final String billingName;
  final String customerCode;
}

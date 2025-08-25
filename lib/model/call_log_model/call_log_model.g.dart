// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallLogModel _$CallLogModelFromJson(Map<String, dynamic> json) => CallLogModel(
  callLogId: json['CallLogID'] as String?,
  customercode: json['customercode'] as String?,
  dot: json['dot'] as String?,
  tot: json['tot'] as String?,
  attended: json['attended'] as String?,
  actionNeeded: json['action_needed'] as String?,
  staffCode: json['StaffCode'] as String?,
  mobileNumber: json['MobileNumber'] as String?,
  deviceId: json['DeviceId'] as String?,
  customerCode: json['CustomerCode'] as String?,
  brandName: json['BrandName'] as String?,
  billingName: json['BillingName'] as String?,
  registredMobileNumber: json['RegistredMobileNumber'] as String?,
);

Map<String, dynamic> _$CallLogModelToJson(CallLogModel instance) =>
    <String, dynamic>{
      'CallLogID': instance.callLogId,
      'customercode': instance.customercode,
      'dot': instance.dot,
      'tot': instance.tot,
      'attended': instance.attended,
      'action_needed': instance.actionNeeded,
      'StaffCode': instance.staffCode,
      'MobileNumber': instance.mobileNumber,
      'DeviceId': instance.deviceId,
      'CustomerCode': instance.customerCode,
      'BrandName': instance.brandName,
      'BillingName': instance.billingName,
      'RegistredMobileNumber': instance.registredMobileNumber,
    };

import 'package:json_annotation/json_annotation.dart';

part 'call_log_model.g.dart';

@JsonSerializable()
class CallLogModel {
	@JsonKey(name: 'CallLogID') 
	String? callLogId;
	String? customercode;
	String? dot;
	String? tot;
	String? attended;
	@JsonKey(name: 'action_needed') 
	String? actionNeeded;
	@JsonKey(name: 'StaffCode') 
	String? staffCode;
	@JsonKey(name: 'MobileNumber') 
	String? mobileNumber;
	@JsonKey(name: 'DeviceId') 
	String? deviceId;
	@JsonKey(name: 'CustomerCode') 
	String? customerCode;
	@JsonKey(name: 'BrandName') 
	String? brandName;
	@JsonKey(name: 'BillingName') 
	String? billingName;
	@JsonKey(name: 'RegistredMobileNumber') 
	String? registredMobileNumber;

	CallLogModel({
		this.callLogId, 
		this.customercode, 
		this.dot, 
		this.tot, 
		this.attended, 
		this.actionNeeded, 
		this.staffCode, 
		this.mobileNumber, 
		this.deviceId, 
		this.customerCode, 
		this.brandName, 
		this.billingName, 
		this.registredMobileNumber, 
	});

	factory CallLogModel.fromJson(Map<String, dynamic> json) {
		return _$CallLogModelFromJson(json);
	}

	Map<String, dynamic> toJson() => _$CallLogModelToJson(this);

	CallLogModel copyWith({
		String? callLogId,
		String? customercode,
		String? dot,
		String? tot,
		String? attended,
		String? actionNeeded,
		String? staffCode,
		String? mobileNumber,
		String? deviceId,
		String? customerCode,
		String? brandName,
		String? billingName,
		String? registredMobileNumber,
	}) {
		return CallLogModel(
			callLogId: callLogId ?? this.callLogId,
			customercode: customercode ?? this.customercode,
			dot: dot ?? this.dot,
			tot: tot ?? this.tot,
			attended: attended ?? this.attended,
			actionNeeded: actionNeeded ?? this.actionNeeded,
			staffCode: staffCode ?? this.staffCode,
			mobileNumber: mobileNumber ?? this.mobileNumber,
			deviceId: deviceId ?? this.deviceId,
			customerCode: customerCode ?? this.customerCode,
			brandName: brandName ?? this.brandName,
			billingName: billingName ?? this.billingName,
			registredMobileNumber: registredMobileNumber ?? this.registredMobileNumber,
		);
	}
}

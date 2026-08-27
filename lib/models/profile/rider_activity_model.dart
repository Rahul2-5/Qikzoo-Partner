class RiderActivityDay {
  final String date;
  final int onlineSeconds;
  const RiderActivityDay({required this.date, required this.onlineSeconds});
  factory RiderActivityDay.fromJson(Map<String, dynamic> j) => RiderActivityDay(
        date: j['date']?.toString() ?? '',
        onlineSeconds: (j['onlineSeconds'] as num?)?.toInt() ?? 0,
      );
}

class RiderActivityWeek {
  final String startDate, endDate;
  final int onlineSeconds;
  final List<RiderActivityDay> days;
  const RiderActivityWeek({
    required this.startDate,
    required this.endDate,
    required this.onlineSeconds,
    required this.days,
  });
  factory RiderActivityWeek.fromJson(Map<String, dynamic> j) =>
      RiderActivityWeek(
        startDate: j['startDate']?.toString() ?? '',
        endDate: j['endDate']?.toString() ?? '',
        onlineSeconds: (j['onlineSeconds'] as num?)?.toInt() ?? 0,
        days: (j['days'] as List? ?? const [])
            .map((x) => RiderActivityDay.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
      );
}

class RiderLogin {
  final String createdAt;
  final String? userAgent, ipAddress;
  const RiderLogin({required this.createdAt, this.userAgent, this.ipAddress});
  factory RiderLogin.fromJson(Map<String, dynamic> j) => RiderLogin(
        createdAt: j['createdAt']?.toString() ?? '',
        userAgent: j['userAgent']?.toString(),
        ipAddress: j['ipAddress']?.toString(),
      );
}

class RiderActivity {
  final RiderActivityDay today;
  final List<RiderActivityWeek> weeks;
  final List<RiderLogin> logins;
  const RiderActivity({
    required this.today,
    required this.weeks,
    required this.logins,
  });
  factory RiderActivity.fromJson(Map<String, dynamic> j) => RiderActivity(
        today: RiderActivityDay.fromJson(
          Map<String, dynamic>.from(j['today'] is Map ? j['today'] : const {}),
        ),
        weeks: (j['weeks'] as List? ?? const [])
            .map(
                (x) => RiderActivityWeek.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        logins: (j['logins'] as List? ?? const [])
            .map((x) => RiderLogin.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
      );
}

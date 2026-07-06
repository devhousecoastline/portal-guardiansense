/// Plano do usuário — define quantos aparelhos físicos o portal exibe.
class UserPlan {
  const UserPlan({
    required this.plan,
    required this.deviceLimit,
  });

  final String plan;
  final int deviceLimit;

  bool get isFree => plan == 'free';

  static const free = UserPlan(plan: 'free', deviceLimit: 1);

  factory UserPlan.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return UserPlan.free;

    final plan = data['plan'] as String? ?? 'free';
    final explicit = (data['deviceLimit'] as num?)?.toInt();

    final limit = explicit ??
        switch (plan) {
          'pro' => 5,
          'family' => 10,
          _ => 1,
        };

    return UserPlan(
      plan: plan,
      deviceLimit: limit.clamp(1, 99),
    );
  }
}

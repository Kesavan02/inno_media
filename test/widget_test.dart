import 'package:flutter_test/flutter_test.dart';
import 'package:inno_media/core/rate_limiter/rate_limiter.dart';
import 'package:inno_media/core/utils/password_hasher.dart';
import 'package:inno_media/features/dynamic_form/domain/entities/conditional_rule_entity.dart';
import 'package:inno_media/features/dynamic_form/domain/entities/form_field_config_entity.dart';

void main() {
  group('PasswordHasher Tests', () {
    test('Password hashing produces consistent salted hash and verifies', () {
      const rawPassword = 'Password@123';
      const salt = 'unique_user_salt_123';
      final hash = PasswordHasher.hashPassword(rawPassword, userSalt: salt);

      expect(hash, isNotEmpty);
      expect(hash, isNot(equals(rawPassword)));

      final isValid = PasswordHasher.verifyPassword(
        rawPassword: rawPassword,
        storedHash: hash,
        userSalt: salt,
      );
      expect(isValid, isTrue);

      final isWrongValid = PasswordHasher.verifyPassword(
        rawPassword: 'WrongPassword',
        storedHash: hash,
        userSalt: salt,
      );
      expect(isWrongValid, isFalse);
    });
  });

  group('RateLimiter Tests', () {
    test('RateLimiter enforces limit and blocks rapid calls', () {
      final limiter = RateLimiter(maxRequests: 2, window: const Duration(seconds: 1));
      expect(limiter.isAllowed('action_1'), isTrue);
      limiter.acquire('action_1');
      expect(limiter.isAllowed('action_1'), isTrue);
      limiter.acquire('action_1');

      // 3rd call should not be allowed
      expect(limiter.isAllowed('action_1'), isFalse);
      expect(() => limiter.acquire('action_1'), throwsException);
    });
  });

  group('Dynamic Form Validation & Conditional Rules Tests', () {
    test('ConditionalRuleEntity evaluates equals correctly', () {
      const rule = ConditionalRuleEntity(field: 'is_married', equals: true);
      expect(rule.evaluate({'is_married': true}), isTrue);
      expect(rule.evaluate({'is_married': false}), isFalse);
      expect(rule.evaluate({}), isFalse);
    });

    test('FormFieldConfigEntity validates email and length correctly', () {
      const emailField = FormFieldConfigEntity(
        id: 'email',
        type: FormFieldType.email,
        label: 'Email',
        required: true,
      );

      expect(emailField.validate(null), isNotNull);
      expect(emailField.validate('invalid-email'), isNotNull);
      expect(emailField.validate('user@domain.com'), isNull);
    });
  });
}

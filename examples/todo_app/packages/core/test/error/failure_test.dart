import 'package:flutter_test/flutter_test.dart';
import 'package:core/error/failure.dart';

void main() {
  group('Failure', () {
    group('DatabaseFailure', () {
      test('should create database failure with message', () {
        const failure = Failure.database(message: 'Database error');

        expect(failure, isA<DatabaseFailure>());
        failure.when(
          database: (message, exception) {
            expect(message, 'Database error');
            expect(exception, isNull);
          },
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should create database failure with message and exception', () {
        final exception = Exception('DB connection failed');
        final failure = Failure.database(
          message: 'Database error',
          exception: exception,
        );

        failure.when(
          database: (message, ex) {
            expect(message, 'Database error');
            expect(ex, exception);
          },
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should support equality', () {
        const failure1 = Failure.database(message: 'Error');
        const failure2 = Failure.database(message: 'Error');
        const failure3 = Failure.database(message: 'Different');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('ValidationFailure', () {
      test('should create validation failure with message', () {
        const failure = Failure.validation(message: 'Invalid input');

        expect(failure, isA<ValidationFailure>());
        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (message, field) {
            expect(message, 'Invalid input');
            expect(field, isNull);
          },
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should create validation failure with message and field', () {
        const failure = Failure.validation(
          message: 'Invalid input',
          field: 'title',
        );

        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (message, field) {
            expect(message, 'Invalid input');
            expect(field, 'title');
          },
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should support equality', () {
        const failure1 = Failure.validation(message: 'Error', field: 'name');
        const failure2 = Failure.validation(message: 'Error', field: 'name');
        const failure3 = Failure.validation(message: 'Error', field: 'email');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('NotFoundFailure', () {
      test('should create notFound failure with message', () {
        const failure = Failure.notFound(message: 'Entity not found');

        expect(failure, isA<NotFoundFailure>());
        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (message, entityId) {
            expect(message, 'Entity not found');
            expect(entityId, isNull);
          },
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should create notFound failure with message and entityId', () {
        const failure = Failure.notFound(
          message: 'Entity not found',
          entityId: '123',
        );

        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (message, entityId) {
            expect(message, 'Entity not found');
            expect(entityId, '123');
          },
          cache: (_, __) => fail('Should not be cache'),
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should support equality', () {
        const failure1 = Failure.notFound(message: 'Not found', entityId: '1');
        const failure2 = Failure.notFound(message: 'Not found', entityId: '1');
        const failure3 = Failure.notFound(message: 'Not found', entityId: '2');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('CacheFailure', () {
      test('should create cache failure with message', () {
        const failure = Failure.cache(message: 'Cache error');

        expect(failure, isA<CacheFailure>());
        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (message, exception) {
            expect(message, 'Cache error');
            expect(exception, isNull);
          },
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should create cache failure with message and exception', () {
        final exception = Exception('Cache read failed');
        final failure = Failure.cache(
          message: 'Cache error',
          exception: exception,
        );

        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (message, ex) {
            expect(message, 'Cache error');
            expect(ex, exception);
          },
          unknown: (_, __) => fail('Should not be unknown'),
        );
      });

      test('should support equality', () {
        const failure1 = Failure.cache(message: 'Error');
        const failure2 = Failure.cache(message: 'Error');
        const failure3 = Failure.cache(message: 'Different');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('UnknownFailure', () {
      test('should create unknown failure with message', () {
        const failure = Failure.unknown(message: 'Unknown error');

        expect(failure, isA<UnknownFailure>());
        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (message, error) {
            expect(message, 'Unknown error');
            expect(error, isNull);
          },
        );
      });

      test('should create unknown failure with message and error', () {
        const error = 'Some error object';
        const failure = Failure.unknown(
          message: 'Unknown error',
          error: error,
        );

        failure.when(
          database: (_, __) => fail('Should not be database'),
          validation: (_, __) => fail('Should not be validation'),
          notFound: (_, __) => fail('Should not be notFound'),
          cache: (_, __) => fail('Should not be cache'),
          unknown: (message, err) {
            expect(message, 'Unknown error');
            expect(err, error);
          },
        );
      });

      test('should support equality', () {
        const failure1 = Failure.unknown(message: 'Error', error: 'err1');
        const failure2 = Failure.unknown(message: 'Error', error: 'err1');
        const failure3 = Failure.unknown(message: 'Error', error: 'err2');

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('maybeWhen', () {
      test('should call specific case when matched', () {
        const failure = Failure.database(message: 'DB error');

        final result = failure.maybeWhen(
          database: (message, _) => 'Database: $message',
          orElse: () => 'Other',
        );

        expect(result, 'Database: DB error');
      });

      test('should call orElse when not matched', () {
        const failure = Failure.validation(message: 'Validation error');

        final result = failure.maybeWhen(
          database: (_, __) => 'Database',
          orElse: () => 'Other',
        );

        expect(result, 'Other');
      });
    });

    group('map', () {
      test('should map to correct type', () {
        const failure = Failure.database(message: 'Error');

        final result = failure.map(
          database: (f) => 'database',
          validation: (f) => 'validation',
          notFound: (f) => 'notFound',
          cache: (f) => 'cache',
          unknown: (f) => 'unknown',
        );

        expect(result, 'database');
      });
    });

    group('maybeMap', () {
      test('should map when matched', () {
        const failure = Failure.validation(message: 'Error');

        final result = failure.maybeMap(
          validation: (f) => 'validation',
          orElse: () => 'other',
        );

        expect(result, 'validation');
      });

      test('should use orElse when not matched', () {
        const failure = Failure.notFound(message: 'Error');

        final result = failure.maybeMap(
          validation: (f) => 'validation',
          orElse: () => 'other',
        );

        expect(result, 'other');
      });
    });
  });
}

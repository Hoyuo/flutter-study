import 'package:flutter_test/flutter_test.dart';
import 'package:core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateTaskTitle', () {
      test('should return null for valid title', () {
        expect(Validators.validateTaskTitle('Valid title'), isNull);
      });

      test('should return null for title at max length', () {
        final title = 'a' * 100;
        expect(Validators.validateTaskTitle(title), isNull);
      });

      test('should return error for null value', () {
        expect(
          Validators.validateTaskTitle(null),
          'Title is required',
        );
      });

      test('should return error for empty string', () {
        expect(
          Validators.validateTaskTitle(''),
          'Title is required',
        );
      });

      test('should return error for string with only spaces', () {
        expect(
          Validators.validateTaskTitle('   '),
          'Title is required',
        );
      });

      test('should return error for string with only tabs', () {
        expect(
          Validators.validateTaskTitle('\t\t'),
          'Title is required',
        );
      });

      test('should return error for string exceeding 100 characters', () {
        final title = 'a' * 101;
        expect(
          Validators.validateTaskTitle(title),
          'Title must be less than 100 characters',
        );
      });

      test('should accept title with leading and trailing spaces', () {
        expect(Validators.validateTaskTitle('  Valid title  '), isNull);
      });

      test('should accept title with single character', () {
        expect(Validators.validateTaskTitle('a'), isNull);
      });

      test('should accept title with numbers', () {
        expect(Validators.validateTaskTitle('Task 123'), isNull);
      });

      test('should accept title with special characters', () {
        expect(Validators.validateTaskTitle('Task #1 - Important!'), isNull);
      });

      test('should accept title with unicode characters', () {
        expect(Validators.validateTaskTitle('할일 목록'), isNull);
      });

      test('should reject very long title', () {
        final title = 'a' * 200;
        expect(
          Validators.validateTaskTitle(title),
          'Title must be less than 100 characters',
        );
      });

      test('should handle mixed whitespace', () {
        expect(
          Validators.validateTaskTitle('  \n\t  '),
          'Title is required',
        );
      });
    });

    group('validateCategoryName', () {
      test('should return null for valid category name', () {
        expect(Validators.validateCategoryName('Work'), isNull);
      });

      test('should return null for category name at max length', () {
        final name = 'a' * 50;
        expect(Validators.validateCategoryName(name), isNull);
      });

      test('should return error for null value', () {
        expect(
          Validators.validateCategoryName(null),
          'Category name is required',
        );
      });

      test('should return error for empty string', () {
        expect(
          Validators.validateCategoryName(''),
          'Category name is required',
        );
      });

      test('should return error for string with only spaces', () {
        expect(
          Validators.validateCategoryName('   '),
          'Category name is required',
        );
      });

      test('should return error for string exceeding 50 characters', () {
        final name = 'a' * 51;
        expect(
          Validators.validateCategoryName(name),
          'Category name must be less than 50 characters',
        );
      });

      test('should accept category name with leading and trailing spaces', () {
        expect(Validators.validateCategoryName('  Work  '), isNull);
      });

      test('should accept single character category name', () {
        expect(Validators.validateCategoryName('A'), isNull);
      });

      test('should accept category name with numbers', () {
        expect(Validators.validateCategoryName('Category 1'), isNull);
      });

      test('should accept category name with special characters', () {
        expect(Validators.validateCategoryName('Work & Projects'), isNull);
      });

      test('should accept category name with unicode characters', () {
        expect(Validators.validateCategoryName('업무'), isNull);
      });

      test('should reject very long category name', () {
        final name = 'a' * 100;
        expect(
          Validators.validateCategoryName(name),
          'Category name must be less than 50 characters',
        );
      });

      test('should handle whitespace variations', () {
        expect(
          Validators.validateCategoryName('\n\t'),
          'Category name is required',
        );
      });

      test('should accept exactly 50 characters', () {
        final name = 'a' * 50;
        expect(Validators.validateCategoryName(name), isNull);
      });

      test('should reject 51 characters', () {
        final name = 'a' * 51;
        expect(
          Validators.validateCategoryName(name),
          'Category name must be less than 50 characters',
        );
      });
    });

    group('validateDescription', () {
      test('should return null for valid description', () {
        expect(Validators.validateDescription('A valid description'), isNull);
      });

      test('should return null for null value', () {
        expect(Validators.validateDescription(null), isNull);
      });

      test('should return null for empty string', () {
        expect(Validators.validateDescription(''), isNull);
      });

      test('should return null for description at max length', () {
        final description = 'a' * 500;
        expect(Validators.validateDescription(description), isNull);
      });

      test('should return error for description exceeding 500 characters', () {
        final description = 'a' * 501;
        expect(
          Validators.validateDescription(description),
          'Description must be less than 500 characters',
        );
      });

      test('should accept short description', () {
        expect(Validators.validateDescription('Short'), isNull);
      });

      test('should accept description with spaces', () {
        expect(
          Validators.validateDescription('A longer description with spaces'),
          isNull,
        );
      });

      test('should accept description with newlines', () {
        expect(
          Validators.validateDescription('Line 1\nLine 2\nLine 3'),
          isNull,
        );
      });

      test('should accept description with special characters', () {
        expect(
          Validators.validateDescription('Description with !@#\$%^&*()'),
          isNull,
        );
      });

      test('should accept description with unicode characters', () {
        expect(
          Validators.validateDescription('설명이 포함된 할일'),
          isNull,
        );
      });

      test('should accept description with numbers', () {
        expect(
          Validators.validateDescription('Description 123 with numbers'),
          isNull,
        );
      });

      test('should reject very long description', () {
        final description = 'a' * 1000;
        expect(
          Validators.validateDescription(description),
          'Description must be less than 500 characters',
        );
      });

      test('should accept description with only spaces', () {
        expect(Validators.validateDescription('     '), isNull);
      });

      test('should accept exactly 500 characters', () {
        final description = 'a' * 500;
        expect(Validators.validateDescription(description), isNull);
      });

      test('should reject 501 characters', () {
        final description = 'a' * 501;
        expect(
          Validators.validateDescription(description),
          'Description must be less than 500 characters',
        );
      });

      test('should handle multiline text within limits', () {
        final description = 'Line 1\n' * 50; // Should be within 500 chars
        if (description.length <= 500) {
          expect(Validators.validateDescription(description), isNull);
        }
      });
    });

    group('edge cases', () {
      test('should handle unicode combining characters in title', () {
        const title = 'café'; // é is a combining character
        expect(Validators.validateTaskTitle(title), isNull);
      });

      test('should handle emoji in title', () {
        const title = 'Task with emoji 😀';
        expect(Validators.validateTaskTitle(title), isNull);
      });

      test('should handle emoji in category name', () {
        const name = '📁 Documents';
        expect(Validators.validateCategoryName(name), isNull);
      });

      test('should handle emoji in description', () {
        const description = 'Description with emoji 🎉';
        expect(Validators.validateDescription(description), isNull);
      });

      test('should handle zero-width characters', () {
        const title = 'Title\u200Bwith\u200Bzero\u200Bwidth';
        expect(Validators.validateTaskTitle(title), isNull);
      });

      test('should handle right-to-left text', () {
        const title = 'مهمة'; // Arabic text
        expect(Validators.validateTaskTitle(title), isNull);
      });

      test('should handle mixed scripts', () {
        const title = 'Task タスク 任务';
        expect(Validators.validateTaskTitle(title), isNull);
      });
    });

    group('boundary tests', () {
      test('title with exactly 100 characters should be valid', () {
        final title = 'a' * 100;
        expect(Validators.validateTaskTitle(title), isNull);
        expect(title.length, 100);
      });

      test('title with 101 characters should be invalid', () {
        final title = 'a' * 101;
        expect(
          Validators.validateTaskTitle(title),
          'Title must be less than 100 characters',
        );
        expect(title.length, 101);
      });

      test('category with exactly 50 characters should be valid', () {
        final name = 'a' * 50;
        expect(Validators.validateCategoryName(name), isNull);
        expect(name.length, 50);
      });

      test('category with 51 characters should be invalid', () {
        final name = 'a' * 51;
        expect(
          Validators.validateCategoryName(name),
          'Category name must be less than 50 characters',
        );
        expect(name.length, 51);
      });

      test('description with exactly 500 characters should be valid', () {
        final description = 'a' * 500;
        expect(Validators.validateDescription(description), isNull);
        expect(description.length, 500);
      });

      test('description with 501 characters should be invalid', () {
        final description = 'a' * 501;
        expect(
          Validators.validateDescription(description),
          'Description must be less than 500 characters',
        );
        expect(description.length, 501);
      });
    });

    group('whitespace handling', () {
      test('should trim whitespace for title validation', () {
        expect(Validators.validateTaskTitle('  a  '), isNull);
      });

      test('should trim whitespace for category validation', () {
        expect(Validators.validateCategoryName('  Work  '), isNull);
      });

      test('should not trim whitespace for description validation', () {
        // Description validation doesn't check for emptiness
        expect(Validators.validateDescription('     '), isNull);
      });

      test('should reject title with only newlines', () {
        expect(
          Validators.validateTaskTitle('\n\n\n'),
          'Title is required',
        );
      });

      test('should reject category with only tabs', () {
        expect(
          Validators.validateCategoryName('\t\t\t'),
          'Category name is required',
        );
      });
    });
  });
}

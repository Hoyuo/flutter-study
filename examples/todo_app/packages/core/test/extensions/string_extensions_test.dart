import 'package:flutter_test/flutter_test.dart';
import 'package:core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('capitalize', () {
      test('should capitalize first letter of lowercase string', () {
        expect('hello'.capitalize, 'Hello');
      });

      test('should not change already capitalized string', () {
        expect('Hello'.capitalize, 'Hello');
      });

      test('should handle single character string', () {
        expect('a'.capitalize, 'A');
      });

      test('should return empty string for empty input', () {
        expect(''.capitalize, '');
      });

      test('should only capitalize first letter', () {
        expect('hello world'.capitalize, 'Hello world');
      });

      test('should handle uppercase input', () {
        expect('HELLO'.capitalize, 'HELLO');
      });

      test('should handle mixed case', () {
        expect('hELLO'.capitalize, 'HELLO');
      });

      test('should handle special characters', () {
        expect('!hello'.capitalize, '!hello');
      });

      test('should handle numbers', () {
        expect('123abc'.capitalize, '123abc');
      });
    });

    group('titleCase', () {
      test('should capitalize first letter of each word', () {
        expect('hello world'.titleCase, 'Hello World');
      });

      test('should handle single word', () {
        expect('hello'.titleCase, 'Hello');
      });

      test('should handle multiple spaces', () {
        expect('hello  world'.titleCase, 'Hello  World');
      });

      test('should return empty string for empty input', () {
        expect(''.titleCase, '');
      });

      test('should handle already title cased string', () {
        expect('Hello World'.titleCase, 'Hello World');
      });

      test('should handle all uppercase', () {
        expect('HELLO WORLD'.titleCase, 'HELLO WORLD');
      });

      test('should handle mixed case', () {
        expect('hELLO wORLD'.titleCase, 'HELLO WORLD');
      });

      test('should handle single character words', () {
        expect('a b c'.titleCase, 'A B C');
      });

      test('should handle multiple words', () {
        expect('the quick brown fox'.titleCase, 'The Quick Brown Fox');
      });

      test('should handle words with numbers', () {
        expect('hello 123 world'.titleCase, 'Hello 123 World');
      });

      test('should handle special characters', () {
        expect('hello-world test'.titleCase, 'Hello-world Test');
      });
    });

    group('isBlank', () {
      test('should return true for empty string', () {
        expect(''.isBlank, true);
      });

      test('should return true for string with only spaces', () {
        expect('   '.isBlank, true);
      });

      test('should return true for string with tabs', () {
        expect('\t\t'.isBlank, true);
      });

      test('should return true for string with newlines', () {
        expect('\n\n'.isBlank, true);
      });

      test('should return true for mixed whitespace', () {
        expect('  \t\n  '.isBlank, true);
      });

      test('should return false for non-empty string', () {
        expect('hello'.isBlank, false);
      });

      test('should return false for string with content and spaces', () {
        expect('  hello  '.isBlank, false);
      });

      test('should return false for single character', () {
        expect('a'.isBlank, false);
      });

      test('should return false for special characters', () {
        expect('!'.isBlank, false);
      });
    });

    group('isNotBlank', () {
      test('should return false for empty string', () {
        expect(''.isNotBlank, false);
      });

      test('should return false for string with only spaces', () {
        expect('   '.isNotBlank, false);
      });

      test('should return false for whitespace', () {
        expect('\t\n '.isNotBlank, false);
      });

      test('should return true for non-empty string', () {
        expect('hello'.isNotBlank, true);
      });

      test('should return true for string with content and spaces', () {
        expect('  hello  '.isNotBlank, true);
      });

      test('should return true for single character', () {
        expect('a'.isNotBlank, true);
      });

      test('should return true for numbers', () {
        expect('123'.isNotBlank, true);
      });
    });

    group('truncate', () {
      test('should not truncate if length is within max', () {
        expect('hello'.truncate(10), 'hello');
      });

      test('should truncate and add ellipsis if exceeds max length', () {
        expect('hello world'.truncate(8), 'hello...');
      });

      test('should use custom suffix', () {
        expect('hello world'.truncate(8, suffix: '…'), 'hello w…');
      });

      test('should handle exact length match', () {
        expect('hello'.truncate(5), 'hello');
      });

      test('should handle very short max length', () {
        expect('hello'.truncate(3), '...');
      });

      test('should handle empty string', () {
        expect(''.truncate(10), '');
      });

      test('should handle single character', () {
        expect('a'.truncate(1), 'a');
      });

      test('should truncate long text correctly', () {
        const longText = 'This is a very long text that needs to be truncated';
        final truncated = longText.truncate(20);
        expect(truncated.length, 20);
        expect(truncated.endsWith('...'), true);
      });

      test('should handle custom suffix length in calculation', () {
        const text = 'hello world';
        final truncated = text.truncate(10, suffix: ' [more]');
        expect(truncated.length, lessThanOrEqualTo(10));
      });

      test('should handle zero max length', () {
        expect('hello'.truncate(0, suffix: ''), '');
      });
    });
  });

  group('NullableStringExtensions', () {
    group('isNullOrEmpty', () {
      test('should return true for null', () {
        const String? nullString = null;
        expect(nullString.isNullOrEmpty, true);
      });

      test('should return true for empty string', () {
        const String? emptyString = '';
        expect(emptyString.isNullOrEmpty, true);
      });

      test('should return false for non-empty string', () {
        const String? string = 'hello';
        expect(string.isNullOrEmpty, false);
      });

      test('should return false for string with spaces', () {
        const String? string = '   ';
        expect(string.isNullOrEmpty, false);
      });

      test('should return false for single character', () {
        const String? string = 'a';
        expect(string.isNullOrEmpty, false);
      });
    });

    group('isNotNullOrEmpty', () {
      test('should return false for null', () {
        const String? nullString = null;
        expect(nullString.isNotNullOrEmpty, false);
      });

      test('should return false for empty string', () {
        const String? emptyString = '';
        expect(emptyString.isNotNullOrEmpty, false);
      });

      test('should return true for non-empty string', () {
        const String? string = 'hello';
        expect(string.isNotNullOrEmpty, true);
      });

      test('should return true for string with spaces', () {
        const String? string = '   ';
        expect(string.isNotNullOrEmpty, true);
      });

      test('should return true for single character', () {
        const String? string = 'a';
        expect(string.isNotNullOrEmpty, true);
      });
    });

    group('isNullOrBlank', () {
      test('should return true for null', () {
        const String? nullString = null;
        expect(nullString.isNullOrBlank, true);
      });

      test('should return true for empty string', () {
        const String? emptyString = '';
        expect(emptyString.isNullOrBlank, true);
      });

      test('should return true for string with only spaces', () {
        const String? string = '   ';
        expect(string.isNullOrBlank, true);
      });

      test('should return true for string with tabs', () {
        const String? string = '\t\t';
        expect(string.isNullOrBlank, true);
      });

      test('should return true for string with newlines', () {
        const String? string = '\n\n';
        expect(string.isNullOrBlank, true);
      });

      test('should return true for mixed whitespace', () {
        const String? string = '  \t\n  ';
        expect(string.isNullOrBlank, true);
      });

      test('should return false for non-empty string', () {
        const String? string = 'hello';
        expect(string.isNullOrBlank, false);
      });

      test('should return false for string with content and spaces', () {
        const String? string = '  hello  ';
        expect(string.isNullOrBlank, false);
      });

      test('should return false for single character', () {
        const String? string = 'a';
        expect(string.isNullOrBlank, false);
      });

      test('should return false for special characters', () {
        const String? string = '!';
        expect(string.isNullOrBlank, false);
      });
    });

    group('edge cases', () {
      test('should handle unicode characters', () {
        const String? emoji = '😀';
        expect(emoji.isNullOrEmpty, false);
        expect(emoji.isNullOrBlank, false);
      });

      test('should handle very long strings', () {
        final longString = 'a' * 10000;
        expect(longString.isNullOrEmpty, false);
        expect(longString.isNullOrBlank, false);
      });

      test('should handle strings with only unicode whitespace', () {
        const String? string = '\u00A0\u00A0'; // Non-breaking spaces
        // trim() handles unicode whitespace
        expect(string.isNullOrBlank, true);
      });
    });
  });

  group('Integration tests', () {
    test('should chain multiple extension methods', () {
      const String text = 'hello world';
      expect(text.capitalize.truncate(8), 'Hello...');
    });

    test('should work with nullable and non-nullable extensions', () {
      const String? text = '  hello  ';
      if (text.isNotNullOrEmpty) {
        expect(text.isBlank, false);
        expect(text.capitalize, '  hello  '); // Only first char capitalized
      }
    });

    test('should handle complex scenarios', () {
      const String text = 'the quick brown fox jumps over the lazy dog';
      final titleCased = text.titleCase;
      final truncated = titleCased.truncate(20);

      expect(titleCased, 'The Quick Brown Fox Jumps Over The Lazy Dog');
      expect(truncated, 'The Quick Brown F...');
    });
  });
}

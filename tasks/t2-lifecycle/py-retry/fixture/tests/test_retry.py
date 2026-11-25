import unittest

from retrylib.retry import retry


class RetryTest(unittest.TestCase):
    def test_returns_on_first_success(self):
        self.assertEqual(retry(lambda: 7), 7)

    def test_succeeds_after_failures(self):
        calls = iter([ValueError, ValueError, 42])

        def flaky():
            item = next(calls)
            if isinstance(item, type) and issubclass(item, Exception):
                raise item("nope")
            return item

        self.assertEqual(retry(flaky), 42)


if __name__ == "__main__":
    unittest.main()

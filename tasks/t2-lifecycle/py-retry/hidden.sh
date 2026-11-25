cd "$(dirname "$0")"
python3 -m unittest discover tests > /dev/null 2>&1 || { echo "FAIL: unittest"; exit 1; }

cat > tests/test_hidden.py <<'EOF'
import unittest
from retrylib.retry import retry


class HiddenTest(unittest.TestCase):
    def test_raises_last_exception(self):
        def always():
            raise RuntimeError("final")
        with self.assertRaises(RuntimeError):
            retry(always, attempts=2)

    def test_exact_attempt_count(self):
        calls = [0]
        def counting():
            calls[0] += 1
            raise ValueError("x")
        try:
            retry(counting, attempts=3)
        except ValueError:
            pass
        self.assertEqual(calls[0], 3)


if __name__ == "__main__":
    unittest.main()
EOF
python3 -m unittest discover tests > /dev/null 2>&1 || { echo "FAIL: hidden cases"; rm -f tests/test_hidden.py; exit 1; }
rm -f tests/test_hidden.py
exit 0

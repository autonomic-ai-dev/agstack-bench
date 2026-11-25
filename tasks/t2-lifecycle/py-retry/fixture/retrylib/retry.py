import time


def retry(fn, attempts=3, delay=0.0):
    last = None
    for _ in range(attempts + 1):
        try:
            return fn()
        except Exception as exc:
            last = exc
            time.sleep(delay)
    return None

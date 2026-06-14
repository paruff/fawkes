def add(a: int | float, b: int | float) -> int | float:
    """Return the sum of a and b."""
    return a + b


def subtract(a: int | float, b: int | float) -> int | float:
    """Return the difference of a and b."""
    return a - b


def multiply(a: int | float, b: int | float) -> int | float:
    """Return the product of a and b."""
    return a * b


def divide(a: int | float, b: int | float) -> float:
    """Return the quotient of a divided by b."""
    return a / b


def modulo(a: int | float, b: int | float) -> int | float:
    """Return the remainder of a divided by b."""
    return a % b


def power(a: int | float, b: int | float) -> int | float:
    """Return a raised to the power of b."""
    return a**b

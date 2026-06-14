import pytest

from scratch.utils import add, subtract, multiply, divide, modulo, power


def test_add_integers():
    assert add(2, 3) == 5


def test_add_negative_integers():
    assert add(-1, -1) == -2


def test_add_zero():
    assert add(0, 0) == 0


def test_add_floats():
    assert add(1.5, 2.5) == 4.0


def test_add_mixed_types():
    assert add(1, 2.5) == 3.5


def test_subtract_integers():
    assert subtract(5, 3) == 2


def test_subtract_negative_integers():
    assert subtract(-1, -1) == 0


def test_subtract_zero():
    assert subtract(0, 0) == 0


def test_subtract_floats():
    assert subtract(3.5, 1.5) == 2.0


def test_subtract_mixed_types():
    assert subtract(4, 1.5) == 2.5


def test_multiply_integers():
    assert multiply(2, 3) == 6


def test_multiply_negative_integers():
    assert multiply(-2, -3) == 6


def test_multiply_zero():
    assert multiply(5, 0) == 0


def test_multiply_floats():
    assert multiply(1.5, 2.0) == 3.0


def test_multiply_mixed_types():
    assert multiply(3, 2.5) == 7.5


def test_divide_integers():
    assert divide(6, 3) == 2.0


def test_divide_negative_integers():
    assert divide(-6, -3) == 2.0


def test_divide_zero_numerator():
    assert divide(0, 5) == 0.0


def test_divide_floats():
    assert divide(3.0, 2.0) == 1.5


def test_divide_mixed_types():
    assert divide(5, 2.0) == 2.5


def test_divide_by_zero_raises():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)


def test_modulo():
    assert modulo(10, 3) == 1


def test_power_positive_integers():
    assert power(2, 3) == 8


def test_power_zero_exponent():
    assert power(5, 0) == 1


def test_power_negative_exponent():
    assert power(2, -1) == 0.5


def test_power_floats():
    assert power(4.0, 0.5) == 2.0


def test_power_mixed_types():
    assert power(3, 2.0) == 9.0

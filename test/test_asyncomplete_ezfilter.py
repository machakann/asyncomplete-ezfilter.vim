from unittest import TestCase
from python3.asyncomplete_ezfilter import AsyncompleteEzfilter

ezfilter = AsyncompleteEzfilter()


class TestAsyncompleteEzfilter(TestCase):
    def test_jaro_winkler_distance(self):
        self.assertAlmostEqual(ezfilter.jaro_winkler_distance('RICK', 'RICK'),
                               0.0)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('MARTHA', 'MARHTA'),
            0.0388888888888888)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('DWAYNE', 'DUANE'), 0.16)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('DIXON', 'DICKSONX'),
            0.1866666666666666)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('ABCDE', 'FGHIJ'), 1.0)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('ABCDE', 'abcde'), 0.0)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('ABCDE', 'abcde', ignorecase=True),
            0.0)

        self.assertAlmostEqual(
            ezfilter.jaro_winkler_distance('ABCDE', 'abcde', ignorecase=False),
            1.0)

        self.assertGreater(
            ezfilter.jaro_winkler_distance('background', 'background-imag'),
            ezfilter.jaro_winkler_distance('background-image',
                                           'background-imag'))

    def test_optimal_string_alignment_distance(self):
        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('RICK', 'RICK'), 0)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('MARTHA', 'MARHTA'), 1)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('DWAYNE', 'DUANE'), 2)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('DIXON', 'DICKSONX'), 4)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('ABCDE', 'FGHIJ'), 5)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('ABCDE', 'abcde'), 0)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('ABCDE',
                                                       'abcde',
                                                       ignorecase=True), 0)

        self.assertAlmostEqual(
            ezfilter.optimal_string_alignment_distance('ABCDE',
                                                       'abcde',
                                                       ignorecase=False), 5)

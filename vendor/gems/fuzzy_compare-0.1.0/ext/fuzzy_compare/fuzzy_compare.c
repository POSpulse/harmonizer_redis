#include "ruby.h"
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "fuzzy_compare.h"

void Init_fuzzy_compare()
{
    FuzzyCompare = rb_define_module("FuzzyCompare");
    rb_define_method(FuzzyCompare, "white_similarity", method_white_similarity, 2);
}

inline bool makes_bad_pair(char *str, int index)
{
    return (str[index] == ' ' || str[index+1] == ' ');
}

inline bool is_pair_equal(char *x_pair, char *y_pair)
{
    return (x_pair[0] == y_pair[0] && x_pair[1] == y_pair[1]);
}

struct PairHolder {
    int pair_count;
    char **pairs;
};

Pair generate_pairs(char *str)
{
    Pair str_pairs;
    int max_pair_number = strlen(str) - 1;
    str_pairs.pairs = malloc(max_pair_number * sizeof(char *));

    int pair_count = 0;
    for (int i = 0; i < max_pair_number; i++) {
        if (!makes_bad_pair(str, i))
        {
            str_pairs.pairs[pair_count] = str + i;
            pair_count++;
        }
    }
    str_pairs.pair_count = pair_count;
    return str_pairs;
}

double white_similarity(char *x_str, char *y_str)
{
    Pair x_pairs = generate_pairs(x_str);
    Pair y_pairs = generate_pairs(y_str);
    int intersect = 0;
    int sum = x_pairs.pair_count + y_pairs.pair_count;

    for (int i = 0; i < x_pairs.pair_count; i++) {
        for (int j = 0; j < y_pairs.pair_count; j++) {
            if (x_pairs.pairs[i] != NULL && y_pairs.pairs[j] != NULL &&
                is_pair_equal(x_pairs.pairs[i], y_pairs.pairs[j])) {
                intersect++;
                y_pairs.pairs[j] = NULL;
                break;
            }
        }
    }

    return 2.0 * (double)intersect / (double)sum;
}

VALUE method_white_similarity(VALUE self, VALUE x_string, VALUE y_string)
{
    char *x_str = StringValueCStr(x_string);
    char *y_str = StringValueCStr(y_string);
    double similarity = white_similarity(x_str, y_str);
    return rb_float_new(similarity);
}

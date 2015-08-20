#include "ruby.h"
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "white_similarity.h"

void Init_white_similarity()
{
    WhiteSimilarity = rb_define_module("WhiteSimilarity");
    rb_define_method(WhiteSimilarity, "score", method_score, 2);
    rb_define_method(WhiteSimilarity, "soft_cos_similarity", method_soft_cos_similarity, 2);
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
    free(x_pairs.pairs);
    free(y_pairs.pairs);

    return 2.0 * (double)intersect / (double)sum;
}

VALUE method_score(VALUE self, VALUE x_string, VALUE y_string)
{
    char *x_str = StringValueCStr(x_string);
    char *y_str = StringValueCStr(y_string);
    if (strlen(x_str) == 1 || strlen(y_str) == 1) {
        return rb_float_new(0.0);
    }
    double similarity = white_similarity(x_str, y_str);
    return rb_float_new(similarity);
}

/* code needed for soft cos similarity calculations */

struct MatrixHolder {
    int len;
    char *raw_string;
    char **words;
    double *values;
};

Matrix generate_matrix(char *matrix_cstr)
{
    Matrix new_matrix;

    new_matrix.raw_string = malloc(strlen(matrix_cstr + 1) + 1);
    strcpy(new_matrix.raw_string, matrix_cstr + 1);

    //printf("%s", new_matrix.raw_string);

    new_matrix.len = (int)matrix_cstr[0];
    new_matrix.words = malloc(new_matrix.len * sizeof(char *));
    new_matrix.values = malloc(new_matrix.len * sizeof(double));

    char *head = new_matrix.raw_string;
    for (int i = 0; i < new_matrix.len; i++) {
        new_matrix.words[i] = head;
        while (*head != ',') {
            head++;
        }
        *head = '\0';
        head++;
    }

    for (int i = 0; i < new_matrix.len; i++) {
        char *curr_value = head;
        while(*head != ',' && *head != '\0') {
            head++;
        }
        if (*head == ',') {
            *head = '\0';
            head++;
        }
        sscanf(curr_value, "%lf", new_matrix.values + i);
    }

    return new_matrix;
}

void free_matrix(Matrix to_free)
{
    free(to_free.raw_string);
    free(to_free.words);
    free(to_free.values);
}

double soft_cos_similarity(char *x_matrix_str, char *y_matrix_str)
{
    Matrix x_matrix = generate_matrix(x_matrix_str);
    Matrix y_matrix = generate_matrix(y_matrix_str);
    double similarity = 0.0;

    for (int i = 0; i < x_matrix.len; i++) {
        for (int j = 0; j < y_matrix.len; j++) {
            double word_sim = white_similarity(x_matrix.words[i], y_matrix.words[j]);
            similarity += (word_sim * x_matrix.values[i] * y_matrix.values[j]);
        }
    }

    free_matrix(x_matrix);
    free_matrix(y_matrix);

    return similarity;
}

VALUE method_soft_cos_similarity(VALUE self, VALUE x_matrix, VALUE y_matrix)
{
    char *x_matrix_cstr = StringValueCStr(x_matrix);
    char *y_matrix_cstr = StringValueCStr(y_matrix);
    return rb_float_new(soft_cos_similarity(x_matrix_cstr, y_matrix_cstr));
}

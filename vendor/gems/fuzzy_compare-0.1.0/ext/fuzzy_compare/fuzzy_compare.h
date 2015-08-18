VALUE FuzzyCompare = Qnil;
void Init_fuzzy_compare();

typedef struct PairHolder Pair;

VALUE method_white_similarity(VALUE self, VALUE x_string, VALUE y_string);
double white_similarity(char *x_str, char *y_str);
Pair generate_pairs(char *str);
inline bool makes_bad_pair(char *str, int index);
inline bool is_pair_equal(char *x_pair, char *y_pair);

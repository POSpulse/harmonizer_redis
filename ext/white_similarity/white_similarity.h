VALUE WhiteSimilarity = Qnil;
void Init_white_similarity();

typedef struct PairHolder Pair;
typedef struct MatrixHolder Matrix;

VALUE method_score(VALUE self, VALUE x_string, VALUE y_string);
double white_similarity(char *x_str, char *y_str);
Pair generate_pairs(char *str);
inline bool makes_bad_pair(char *str, int index);
inline bool is_pair_equal(char *x_pair, char *y_pair);

Matrix generate_matrix(char *matrix_cstr);
void free_matrix(Matrix to_free);
double soft_cos_similarity(char *x_matrix_str, char *y_matrix_str);
VALUE method_soft_cos_similarity(VALUE self, VALUE x_matrix, VALUE y_matrix);

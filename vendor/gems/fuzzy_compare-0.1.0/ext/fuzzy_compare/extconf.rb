require 'mkmf'

$CFLAGS = '--std=c99 -O'

create_makefile('fuzzy_compare/fuzzy_compare')

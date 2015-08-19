require 'mkmf'

$CFLAGS = '--std=c99 -O'

create_makefile('harmonizer_redis/white_similarity')

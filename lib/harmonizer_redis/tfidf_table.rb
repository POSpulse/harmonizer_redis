module HarmonizerRedis
  module TfidfTable
    def TfidfTable.add_document(phrase_id)
      text = HarmonizerRedis::Phrase.get_content(phrase_id)
      word_set = Set.new
      text.split.each do |word|
        unless word_set.include? word
          word_set.add(word)
          Redis.current.incr(word_doc_count_key(word))
        end
        Redis.current.incr(word_count_key(word))
      end
    end

    def TfidfTable.decr_doc_count(word)
      Redis.current.decr(word_doc_count_key(word))
    end

    def TfidfTable.word_doc_count_key(word)
      "Word:[#{word}]:doc_count"
    end

    def TfidfTable.word_count_key(word)
      "Word:[#{word}]:count"
    end
  end
end

module HarmonizerRedis
  module TfidfTable
    def TfidfTable.add_document(phrase_id)
      TfidfTable.incr_doc_count
      text = HarmonizerRedis::Phrase.get_content(phrase_id)
      word_set = Set.new
      text.split.each do |word|
        unless word_set.include? word
          word_set.add(word)
          Redis.current.incr(word_doc_freq_key(word))
        end
        Redis.current.incr(word_count_key(word))
      end
    end

    def TfidfTable.get_score(word)
      doc_freq = get_doc_freq(word) || 0
      word_count = get_count(word) || 0
      doc_count = Tfidf.doc_count
      Math.log(word_count.to_f + 1.0) * Math.log(doc_count / (doc_freq + 1.0))
    end

    def TfidfTable.get_doc_freq(word)
      Redis.current.get(word_doc_freq_key(word))
    end

    def TfidfTable.get_count(word)
      Redis.current.get(word_doc_freq_key(word))
    end

    def TfidfTable.decr_doc_freq(word)
      Redis.current.decr(word_doc_freq_key(word))
    end

    def TfidfTable.doc_count
      Redis.current.get("#{self}:doc_count")
    end

    def TfidfTable.incr_doc_count
      Redis.current.incr("#{self}::TfidfTable:doc_count")
    end

    def TfidfTable.word_doc_freq_key(word)
      "Word:[#{word}]:doc_freq"
    end

    def TfidfTable.word_count_key(word)
      "Word:[#{word}]:count"
    end
  end
end

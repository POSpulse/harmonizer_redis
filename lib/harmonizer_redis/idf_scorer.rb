module HarmonizerRedis
  module IdfScorer
    def IdfScorer.add_document(phrase_id)
      IdfScorer.incr_doc_count
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

    def IdfScorer.get_score(word)
      doc_freq = IdfScorer.get_doc_freq(word) + 0.1
      doc_count = IdfScorer.doc_count + 0.1
      Math.log(0.1+(doc_count / doc_freq))
    end

    # first char is length of phrase (capped at 255 words). Each word(key) is separated
    # by a comma and the keys and values are separated by a vertical bar
    def IdfScorer.serialize_matrix(matrix)
      serialized = "#{matrix.length.chr}#{matrix.keys.join(',')},#{matrix.values.join(',')}"
      serialized
    end

    # Used for soft cosine similarity
    def IdfScorer.calc_soft_matrix(phrase_content)
      matrix = Hash.new(0.0)
      phrase_content.split.each do |word|
        matrix[word] += 1.0
      end

      matrix.each do |word, count|
        updated = (1.0 + Math::log10(count)) * IdfScorer.get_score(word)
        matrix[word] = updated
      end

      #calculate normalization factor
      norm_factor_sqrd = 0.0
      matrix.each do |word_a, value_a|
        matrix.each do |word_b, value_b|
          similarity = WhiteSimilarity.score(word_a, word_b)
          norm_factor_sqrd += (similarity * value_a * value_b)
        end
      end

      #normalize
      factor = Math::sqrt(norm_factor_sqrd)
      matrix.each do |word, value|
        matrix[word] = value / factor
      end
      matrix
    end

    def IdfScorer.cos_similarity(matrix_a, matrix_b)
      similarity = 0.0
      matrix_a.each do |word, value|
        similarity += (value * matrix_b[word])
      end
      similarity
    end

    def IdfScorer.soft_cos_similarity(matrix_a, matrix_b)
      similarity = 0.0
      matrix_a.each do |word_a, value_a|
        matrix_b.each do |word_b, value_b|
          if word_a != word_b
            white_similarity = WhiteSimilarity.score(word_a, word_b)
          else
            white_similarity = 1.0
          end
          similarity += (white_similarity * value_a * value_b)
        end
      end
      similarity
    end

    def IdfScorer.get_doc_freq(word)
      Redis.current.get(word_doc_freq_key(word)).to_f
    end

    def IdfScorer.get_count(word)
      Redis.current.get(word_count_key(word)).to_f
    end

    def IdfScorer.decr_doc_freq(word)
      Redis.current.decr(word_doc_freq_key(word))
      Redis.current.decr("#{self}:doc_count")
    end

    def IdfScorer.doc_count
      Redis.current.get("#{self}:doc_count").to_f
    end

    def IdfScorer.incr_doc_count
      Redis.current.incr("#{self}:doc_count")
    end

    def IdfScorer.word_doc_freq_key(word)
      "Word:[#{word}]:doc_freq"
    end

    def IdfScorer.word_count_key(word)
      "Word:[#{word}]:count"
    end
  end
end

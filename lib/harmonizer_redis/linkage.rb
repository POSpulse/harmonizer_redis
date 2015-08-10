module HarmonizerRedis
  class Linkage < BaseObject
    attr_accessor :content, :phrase

    def initialize(params)
      @id = params[:id]
      @content = params[:content]
      @content_normalized = HarmonizerRedis.normalize_string(@content)
    end

    def save #make sure that new phrase is saved
      #if phrase already exists : set to that phrase
      #otherwise : create a new phrase and set linkage:phrase to that phrase
      existing_phrase = HarmonizerRedis::Phrase.find_by_content(@content_normalized)
      if existing_phrase
        @phrase = existing_phrase
      else
        new_phrase = HarmonizerRedis::Phrase.new(@content_normalized)
        new_phrase.save
        @phrase = "#{new_phrase.class}:#{new_phrase.id}"
      end

      super()
    end

  end
end

module HarmonizerRedis
  class Linkage < BaseObject
    attr_accessor :content, :phrase

    def initialize(params)
      @id = params[:id]
      @content = params[:content]

      #if the phrase already exists : set to that phrase
      #otherwise : create a new phrase and set linkage:phrase to that phrase
    end

  end
end

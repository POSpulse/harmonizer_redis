require 'harmonizer_redis/version'
require 'harmonizer_redis/base_object'
require 'harmonizer_redis/linkage'
require 'harmonizer_redis/phrase'
require 'harmonizer_redis/phrase_group'
require 'active_support/all'

module HarmonizerRedis
  ###String PreProcessing
  def HarmonizerRedis.normalize_string(string)
    ActiveSupport::Inflector.transliterate(string.strip.downcase).
        split(/[^\p{L}0-9]/).delete_if { |x| x.length == 0 }.join(' ')
  end
end

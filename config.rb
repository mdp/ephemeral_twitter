require 'yaml'

FIELDS = [:username, :max_age, :consumer_key, :consumer_secret, :token, :secret, :tweets_to_keep]

class TwitterConfig

  def initialize(filename)
    @params = YAML.load_file(filename)
  end

  def check!
  end

  def method_missing(sym)
    if FIELDS.include?(sym)
      return @params[sym.to_s]
    else
      super
    end
  end
end

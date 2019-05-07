module WpApiClient

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset
    @configuration = Configuration.new
  end

  class Configuration
    attr_accessor :endpoint
    attr_accessor :embed
    attr_accessor :oauth_credentials
    attr_accessor :oauth2_token
    attr_accessor :debug
    attr_accessor :cache
    attr_accessor :basic_auth
    attr_accessor :proxy

    def initialize
      @endpoint = 'http://localhost:8080/wp-json/wp/v2'
      @embed = true
    end

    def define_mapping(relation, type)
      WpApiClient::Relationship.define(relation, type)
    end

    def request_params
      params = {}
      if @embed
        params[:_embed] = true
      end
      params
    end

  end
end

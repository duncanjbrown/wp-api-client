require 'faraday'
require 'faraday_middleware'
require 'faraday-http-cache'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

module WpApiClient
  class Connection

    attr_accessor :headers
    attr_reader :concurrent

    def initialize(configuration)
      @configuration = configuration
      @queue = []
      @conn = Faraday.new(url: configuration.endpoint) do |faraday|

        if configuration.oauth2_token
          faraday.request :oauth2, configuration.oauth2_token
        elsif configuration.oauth_credentials
          faraday.use FaradayMiddleware::OAuth, configuration.oauth_credentials
        end

        if configuration.basic_auth
          faraday.basic_auth(configuration.basic_auth[:username], configuration.basic_auth[:password])
        end

        if configuration.debug
          faraday.response :logger
          faraday.use :instrumentation
        end

        if configuration.cache
          faraday.use :http_cache, store: configuration.cache, shared_cache: false
        end

        if configuration.proxy
          faraday.proxy configuration.proxy
        end

        faraday.use Faraday::Response::RaiseError
        faraday.response :json, :content_type => /\bjson$/
        faraday.adapter  :typhoeus
      end
    end

    # translate requests into wp-api urls
    def get(url, params = {})
      @conn.get url, parse_params(params)
    end

    def post(url, params = {})
      @conn.post url, params
    end

    # requests come in as url/params pairs
    def get_concurrently(requests)
      responses = []
      @conn.in_parallel do
        requests.map do |r|
          responses << get(r[0], r[1])
        end
      end
      responses
    end

private

    def parse_params(params)
      params = @configuration.request_params.merge(params)
      # if _embed is present at all it will have the effect of embedding —
      # even if it's set to "false"
      if params[:_embed] == false
        params.delete(:_embed)
      end
      params
    end


  end
end

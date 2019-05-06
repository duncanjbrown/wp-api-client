module WpApiClient
  class ConcurrentClient < Client

    def get(url, params = {})
      @queue ||= []
      @queue << [api_path_from(url), params]
    end

    def post(url, params = {})
      @queue ||= []
      @queue << [api_path_from(url), params]
    end

    def run
      responses = @connection.get_concurrently(@queue)
      responses.map { |r| native_representation_of(r.body) }
    end

  end
end

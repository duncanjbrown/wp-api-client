module WpApiClient
  class Client

    def initialize(connection)
      @connection = connection
    end

    def get(url, params = {})
      if @concurrent_client
        @concurrent_client.get(api_path_from(url), params)
      else
        response = @connection.get(api_path_from(url), params)
        @headers = response.headers
        native_representation_of response.body
      end
    end

    def post(url, params = {})
      if @concurrent_client
        @concurrent_client.post(api_path_from(url), params)
      else
        response = @connection.post(api_path_from(url), params)
        @headers = response.headers
        native_representation_of response.body
      end
    end

    def concurrently
      @concurrent_client ||= ConcurrentClient.new(@connection)
      yield @concurrent_client
      result = @concurrent_client.run
      @concurrent_client = nil
      result
    end

    private

    def api_path_from(url)
      url.split('wp/v2/').last
    end

    # Take the API response and figure out what it is
    def native_representation_of(response_body)
      # Do we have a collection of objects?
      if response_body.is_a? Array
        WpApiClient::Collection.new(response_body, @headers)
      else
        WpApiClient::Entities::Base.build(response_body)
      end
    end
  end
end

RSpec.describe WpApiClient::Entities::Post do
  describe "calling instance methods on a post", vcr: {cassette_name: 'single_post'} do

    before :each do
      @post = @api.get("posts/1")
    end

    it "returns the title" do
      expect(@post.title).to eq "Hello world!"
    end

    it "returns the date as a Time object" do
      expect(@post.date).to be_a Time
    end

    it "returns the content as HTML" do
      expect(@post.content).to eq "<p>Welcome to WordPress. This is your first post. Edit or delete it, then start writing!</p>\n"
    end

    it "returns its own ID" do
      expect(@post.id).to eq 1
    end

    it "returns its own slug" do
      expect(@post.slug).to eq 'hello-world'
    end

    it "allows its internal resource to be queried directly" do
      expect(@post.resource["slug"]).to eq 'hello-world'
    end

    it "returns its author" do
      expect(@post.author).to be_a WpApiClient::Entities::User 
    end

  end

  describe "meta function" do

    [:oauth, :oauth2].each do |auth_type|
      before :all do
        WpApiClient.reset!
        oauth_credentials = get_test_oauth_credentials

        WpApiClient.configure do |api_client|
          if auth_type == :oauth
            api_client.oauth_credentials = oauth_credentials
          elsif auth_type == :oauth2
            api_client.oauth2_token = oauth_credentials
          end
        end
        @api = WpApiClient.get_client
      end

      after :all do
        WpApiClient.reset!
      end

      it "returns an individual meta value" do
        VCR.use_cassette('single_post_auth', record: :new_episodes) do
          @post = WpApiClient.get_client.get("posts/1")
          expect(@post.meta(:example_metadata_field)).to eq "example_meta_value"
        end
      end

      it "caches" do
        VCR.use_cassette('single_post_auth', record: :new_episodes) do
          @post = WpApiClient.get_client.get("posts/1")
          meta_value = @post.meta(:example_metadata_field)
        end
        VCR.turned_off do
          ::WebMock.disable_net_connect!
          expect {
            @post.meta(:example_associated_post_id)
          }.to_not raise_error
        end
      end

      it "returns the right items from cache" do
        VCR.use_cassette('single_post_auth', record: :new_episodes) do
          @post = WpApiClient.get_client.get("posts/1")
          expect(@post.meta(:example_metadata_field)).to eq "example_meta_value"
          expect(@post.meta(:example_associated_post_id)).to eq "100"
        end
      end
    end
  end
end

RSpec.describe WpApiClient::Collection do
  describe "fetching posts of a certain post type", vcr: {cassette_name: 'custom_post_type_collection', record: :new_episodes} do

    before :each do
      @collection = @api.get("custom_post_type")
    end

    it "returns an array of posts" do
      expect(@collection.first).to be_a WpApiClient::Entities::Post
    end

    it "can paginate" do
      expect(@collection.count).to eq 10
      paged_id = @collection.first.id

      @next_page = @api.get(@collection.next_page)
      expect(@next_page.first.id).to eq (paged_id - 10)

      @previous_page = @api.get(@next_page.previous_page)
      expect(@previous_page.first.id).to eq paged_id

      # no pages left to turn
      expect(@previous_page.previous_page).to eq nil
    end

    it "accepts array and non-array input" do
      single_post = @collection.first
      expect(single_post).not_to be_an Array

      expect {
        WpApiClient::Collection.new(single_post.resource)
      }.not_to raise_error
    end

    it "responds to array methods" do
      expect(@collection.count).to eq 10
      @collection.delete_at(0) # delete_at is Array-only
      expect(@collection.count).to eq 9
    end

    it "should respond to total_pages and total_available" do
      expect(@collection).to respond_to(:total_pages)
      expect(@collection).to respond_to(:total_available)
    end

    it "should have 10 pages and 100 articles" do
      expect(@collection.total_pages).to eq(10)
      expect(@collection.total_available).to eq(100)
    end

    it "throws an error when it tries to parse an error response" do
      expect {
        WpApiClient::Collection.new([{"code"=>"rest_forbidden", "message"=>"You don't have permission to do this.", "data"=>{"status"=>403}}])
      }.to raise_error
    end
  end
end

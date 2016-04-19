# A read-only Ruby client for WP-API v2

This unambitious client provides read-only access for WP-API v2.

It supports authentication via OAuth or Basic Auth.

It can make concurrent requests.

It does not support comments, users or POST requests.

It requires **Ruby 2.3** and is tested against **WP-API 2.0-beta12** on WordPress 4.4.2 and WordPress 4.5.

Support for future WP-API versions depends on the resolution of [this bug](https://github.com/WP-API/wp-api-meta-endpoints/issues/12) introduced in WP-API 2.0-beta13.

## Installation

```ruby
gem install wp-api-client
```

And

```ruby
require 'wp_api_client'
```

## For WordPress versions < 4.5

WP 4.5 introduced a new way of handling relationships in the API. If you're running an older version you should let the client know when you set it up.

```ruby
WpApiClient.configure do |api_client|
  api_client.wp_version = '4.4.2'
end
```

## Usage examples

#### Set up the client and get some posts

```ruby
# create a client

WpApiClient.configure do |api_client|
  api_client.endpoint = 'http://example.com/wp-json/wp/v2'
end

@api = WpApiClient.get_client

# get some posts
posts = @api.get('custom_post_type/') # or "posts/" etc
# => <WpApiClient::Collection:0x007fed432a5660 @resources=[#<WpApiClient::Entities::Post...

posts.map { |p| puts p.title }
# Custom Post Type 99
# Custom Post Type 98
# Custom Post Type 97

term = @posts.first.terms.first
# => #<WpApiClient::Entities::Term:0x007fed42b3e458 @resource={"id"=>2...
```

#### Navigate between posts, terms and taxonomies

```ruby
term.taxonomy
# => #<WpApiClient::Entities::Taxonomy:0x007f9c2c86f1a8 @resource={"name"=>"Custom taxonomy"...

term.posts
# => #<WpApiClient::Collection:0x007fd65d07d588 @resources=[#<WpApiClient::Entities::Post...

# term.posts("custom_post_type").first.terms("category").first.taxonomy... etc etc etc
```

#### Pagination

```ruby
posts = @api.get('posts', page: 2)

posts.count
# => 10

posts.total_available
# => 100

next_page = @api.get(posts.next_page)
# => #<WpApiClient::Collection:0x00bbcafe938827 @resources=[#<WpApiClient::Entities::Post...

page_after_that = @api.get(next_page.next_page)
# => #<WpApiClient::Collection:0x00bbcafe938827 @resources=[#<WpApiClient::Entities::Post...
```

#### Defining relationships

The [REST API docs](http://v2.wp-api.org/extending/linking/) invite you to define
custom relationships to go alongside "http://api.w.org/term" etc.

For example, let's say you have a `person` post type and a post-to-post relation
defined through meta and exposed in the REST API like this:

```php
add_filter( 'rest_prepare_king', function( $data, $king ) {
	if( $king->queen ) {
		$data->add_link(
			'http://api.myuniqueuri.com/marriage',
			rest_url( '/wp/v2/person/'.$king->queen ),
			['embeddable' => true]
		);
	}
	return $data;
}, 10, 2);
```

This will cause the `http://api.myuniqueuri.com/marriage` relation to be reflected
in your `_links` property when you call up the King from the REST API.

But you'll get an error if you try to query this relationship using the client.

```ruby
king = @api.get('person/1')
queen = king.relations("http://api.myuniqueuri.com/marriage").first
# => throws WpApiClient::RelationNotDefined
```

The solution is to register the relationship on configuration:

```ruby
WpApiClient.configure do |c|
  c.define_mapping("http://api.myuniqueuri.com/marriage", :post)
end

...

king = @api.get('person/1')
queen = king.relations("http://api.myuniqueuri.com/marriage").first
# => #<WpApiClient::Entities::Post:0x007fed42b3e458 @resource={"id"=>2...
```

There is currently support for `:post_type`, `:post`, `:term` and `:meta` (key/value) relations.

#### Loading a taxonomy via a slug

WP-API returns an array even if there's only one result, so you need to be careful here

```ruby
term = @api.get('custom_taxonomy', slug: 'term_one').first
taxonomy_name = term.taxonomy.name
posts = term.posts
```

#### OAuth

Provide a symbol-keyed hash of `token`, `token_secret`, `consumer_key` and `consumer_secret` on configuration.

```ruby
WpApiClient.configure do |api_client|
  api_client.oauth_credentials = oauth_credentials_hash
end

client = WpApiClient.get_client
```

#### Basic Auth

Provide a symbol-keyed hash of `username` and `password` on configuration.

```ruby
WpApiClient.configure do |api_client|
  api_client.basic_auth = {username: 'miles', password: 'smile'}
end

client = WpApiClient.get_client
```

## Concurrency

WP-API is _slow_: a typical request takes 0.5s. To mitigate this, I recommend
caching all your responses sensibly, and when you need to fetch, do so concurrently
as far as is possible.

```ruby
results = []
client.concurrently do |api|
  results << api.get('post/1')
  results << api.get('post/2')
  results << api.get('post/3')
end
results
# => [#<WpApiClient::Entities::Post>, #<WpApiClient::Entities::Post, #<WpApiClient::Entities::Post>]
```

## Testing and compatibility

This library comes with VCR cassettes recorded against a local WP installation
running WP-API v2-beta12. It is not tested with other versions.

If you want to make your own VCR cassettes, use [these scripts](https://github.com/duncanjbrown/WP-REST-Test).

To run the tests, invoke `rspec`.

## Structure

### Public Objects

#### `WpApiClient::Client`

Accepts a `WpApiClient::Connection` and exposes a `#get` method.

Pass a URL into `#get` and it will do its best to return usable data.

The second parameter accepts an optional hash of query params.

#### `WpApiClient::Connection`

Initialize with an API endpoint like `http://localhost:8080/wp-json/wp/v2`, then
pass into a new client. Faraday options might be pulled out of here in the future.

### Internal Objects

#### `WpApiClient::Collection`

Wraps a set of `WpApiClient::Entities` in an `Enumerable` interface and provides `next_page`
and `previous_page` methods. Pass these into `@api` and it will give you back the
data you want

```ruby
next_page = @api.get(posts.next_page)
# => #<WpApiClient::Collection:0x00bbcafe938827 @resources=[#<WpApiClient::Entities::Post...
```

#### `WpApiClient::Entities::Base`

Base class for `Post`, `Term`, `Image` and `Taxonomy`, so far. Not all methods are implemented.

## Other

Thanks [WP-API](https://github.com/WP-API/WP-API)!

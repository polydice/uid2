# UID2 - A Ruby API client for Unified ID 2.0

This gem provides an API client for [Unified ID 2.0](https://github.com/UnifiedID2/uid2docs). 

Current supports UID2 API v2.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uid2'
```

## Usage

This gem implements every Unified ID 2.0 APIs.

To create a client:

```ruby
client = Uid2::Client.new do |client|
  c.bearer_token = "YOUR_TOKEN_HERE"
  c.secret_key = "YOUR_SECRET_KEY_HERE"
end
```

Then call methods:

```ruby
# To generate UID2 token
client.generate_token(email: 'foo@bar.com')
client.generate_token(phone: '+886912345678')

# To map UID2 identity
client.generate_identifier(email: 'foo@bar.com')
client.generate_identifier(phone: '+886912345678')

# To get salt buckets
client.get_salt_buckets
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/polydice/uid2. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/uid2/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Uid2 project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/uid2/blob/main/CODE_OF_CONDUCT.md).

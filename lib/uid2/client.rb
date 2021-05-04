require 'net/http/persistent'
require 'faraday'
require 'faraday_middleware'
require 'time'

module Uid2
  class Client
    attr_accessor :bearer_token, :base_url

    def initialize(options = {})
      yield(self) if block_given?

      self.base_url ||= 'https://integ.uidapi.com/v1/'
    end

    def generate_token(params)
      http.get('token/generate', params)
    end

    def validate_token(params)
      http.get('token/validate', params)
    end

    def refresh_token(token)
      http.get('token/refresh', { refresh_token: token })
    end

    def get_salt_buckets(since = Time.now)
      # By default, Ruby's iso8601 generates timezone parts (`T`)
      # which needs to be removed for UID2 APIs
      http.get('identity/buckets', since_timestamp: since.utc.iso8601[0..-2])
    end

    def generate_identifier(params)
      http.get('identity/map', params)
    end

    def batch_generate_identifier(params)
      http.post('identity/map', params)
    end

    private

    def credentials
      {
        "Authorization" => "Bearer #{bearer_token}"
      }
    end

    def http
      @http ||= Faraday.new(
        url: base_url,
        headers: credentials
      ) do |f|
        f.request :json

        f.response :raise_error
        f.response :mashify
        f.response :json

        f.adapter :net_http_persistent
      end
    end
  end
end

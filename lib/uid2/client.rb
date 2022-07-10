# frozen_string_literal: true

require "net/http/persistent"
require "faraday"
require "faraday_middleware"
require "faraday/uid2"
require "time"

module Uid2
  class Client
    attr_accessor :bearer_token, :base_url

    def initialize(_options = {})
      yield(self) if block_given?

      self.base_url ||= "https://prod.uidapi.com/v2/"
    end

    def generate_token(email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      # As stated in doc, if email and email_hash are both supplied in the same request,
      # only the email will return a mapping response.
      params = if email.empty?
        {email_hash: email_hash}
      else
        {email: email}
      end
      http.post("token/generate", params).body
    end

    def validate_token(token:, email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      params = if email.empty?
        {email_hash: email_hash}
      else
        {email: email}
      end

      http.post("token/validate", params.merge(token: token)).body
    end

    def refresh_token(refresh_token:, refresh_response_key:)
      http(is_refresh: true, refresh_response_key: refresh_response_key).post("token/refresh", refresh_token).body
    end

    def get_salt_buckets(since: Time.now)
      # By default, Ruby's iso8601 generates timezone parts (`T`)
      # which needs to be removed for UID2 APIs
      http.post("identity/buckets", since_timestamp: since.utc.iso8601[0..-2]).body
    end

    def generate_identifier(email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      # As stated in doc, if email and email_hash are both supplied in the same request,
      # only the email will return a mapping response.
      params = if email.empty?
        {email_hash: Array(email_hash)}
      else
        {email: Array(email)}
      end

      http.post("identity/map", params).body
    end

    private

    def credentials
      {
        "Authorization" => "Bearer #{bearer_token}"
      }
    end

    def http(is_refresh: false, refresh_response_key: nil)
      Faraday.new(
        url: base_url,
        headers: credentials
      ) do |f|
        f.request :json unless refresh_response_key
        f.request :uid2_encryption, refresh_response_key || ENV["UID2_SECRET_KEY"], is_refresh
        f.adapter :net_http_persistent
      end
    end
  end
end

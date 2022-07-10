# frozen_string_literal: true

require "net/http/persistent"
require "faraday"
require "faraday_middleware"
require "faraday/uid2"
require "time"

module Uid2
  class Client
    attr_accessor :bearer_token, :base_url, :secret_key

    def initialize(_options = {})
      yield(self) if block_given?

      self.base_url ||= "https://prod.uidapi.com/v2/"
    end

    def generate_token(email: nil, email_hash: nil, phone: nil, phone_hash: nil)
      params = {email: email, email_hash: email_hash, phone: phone, phone_hash: phone_hash}.reject { |_, v| v.nil? }
      raise ArgumentError, "One of the argument needs to be provided" if params.empty?
      http.post("token/generate", params).body
    end

    def validate_token(token:, email: nil, email_hash: nil, phone: nil, phone_hash: nil)
      params = {email: email, email_hash: email_hash, phone: phone, phone_hash: phone_hash}.reject { |_, v| v.nil? }
      raise ArgumentError, "One of the argument needs to be provided" if params.empty?

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

    def generate_identifier(email: nil, email_hash: nil, phone: nil, phone_hash: nil)
      params = {email: Array(email), email_hash: Array(email_hash), phone: Array(phone), phone_hash: Array(phone_hash)}.reject { |_, v| v.empty? }
      raise ArgumentError, "One of the argument needs to be provided" if params.empty?

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
        f.request :uid2_encryption, refresh_response_key || secret_key, is_refresh
        f.adapter :net_http_persistent
      end
    end
  end
end

# frozen_string_literal: true

require "net/http/persistent"
require "faraday"
require "faraday_middleware"
require "time"

module Uid2
  class Client
    attr_accessor :bearer_token, :base_url

    def initialize(_options = {})
      yield(self) if block_given?

      self.base_url ||= "https://integ.uidapi.com/v1/"
    end

    def generate_token(email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      # As stated in doc, if email and email_hash are both supplied in the same request,
      # only the email will return a mapping response.
      params = if email.empty?
                 { email_hash: email_hash }
               else
                 { email: email }
               end
      http.get("token/generate", params).body
    end

    def validate_token(token:, email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      params = if email.empty?
                 { email_hash: email_hash }
               else
                 { email: email }
               end

      http.get("token/validate", params.merge(token: token)).body
    end

    def refresh_token(refresh_token:)
      http.get("token/refresh", { refresh_token: refresh_token }).body
    end

    def get_salt_buckets(since: Time.now)
      # By default, Ruby's iso8601 generates timezone parts (`T`)
      # which needs to be removed for UID2 APIs
      http.get("identity/buckets", since_timestamp: since.utc.iso8601[0..-2]).body
    end

    def generate_identifier(email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      # As stated in doc, if email and email_hash are both supplied in the same request,
      # only the email will return a mapping response.
      params = if email.empty?
                 { email_hash: email_hash }
               else
                 { email: email }
               end

      http.get("identity/map", params).body
    end

    def batch_generate_identifier(email: nil, email_hash: nil)
      raise ArgumentError, "Either email or email_hash needs to be provided" if email.nil? && email_hash.nil?

      # As stated in doc, if email and email_hash are both supplied in the same request,
      # only the email will return a mapping response.
      params = if email.empty?
                 { email_hash: Array(email_hash) }
               else
                 { email: Array(email) }
               end

      http.post("identity/map", params).body
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

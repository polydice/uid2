# frozen_string_literal: true

require "faraday"
require "base64"
require "hashie/mash"

module Faraday
  module Uid2
    class Middleware < Faraday::Middleware
      def initialize(app, secret_key, is_refresh, options = {})
        super(app, options)

        @key = Base64.decode64(secret_key)
        @is_refresh = is_refresh
      end

      def call(request_env)
        unless @is_refresh
          @nonce = Random.new.bytes(8)

          cipher = create_cipher.encrypt
          iv = cipher.random_iv

          body = request_env.body
          payload = timestamp_bytes + @nonce + body
          encrypted = cipher.update(payload) + cipher.final
          request_env.body = Base64.strict_encode64(["\x1", iv, encrypted, cipher.auth_tag].join)
        end

        @app.call(request_env).on_complete do |response_env|
          process_response(response_env)
        end
      end

      def process_response(env)
        resp = Base64.decode64(env.body).unpack("C*")
        iv = resp[0..11].pack("C*")
        cipher_text = resp[12...-16].pack("C*")
        auth_tag = resp[-16...-1].pack("C*")

        cipher = create_cipher.decrypt
        cipher.iv = iv
        cipher.auth_tag = auth_tag

        payload = cipher.update(cipher_text) + cipher.final

        data = if @is_refresh
          payload
        else
          timestamp = Time.at(payload[0..7].unpack1("Q>") / 1000.0)
          raise Faraday::ParsingError.new("Response timestamp is too old", env[:response]) if Time.now - timestamp > 5 * 60

          nonce = payload[8..15]
          raise Faraday::ParsingError.new("Nonce mismatch", env[:response]) if nonce != @nonce

          payload[16..]
        end

        env.response_headers["Content-Type"] = "application/json"
        env.body = Hashie::Mash.new(JSON.parse(data))
      end

      def timestamp_bytes
        [(Time.now.to_f * 1000).to_i].pack("Q>")
      end

      def create_cipher
        cipher = OpenSSL::Cipher.new("aes-256-gcm").encrypt
        cipher.padding = 0
        cipher.key = @key
        cipher.auth_data = ""
        cipher
      end
    end
  end
end

require_relative "uid2/middleware"
require "faraday"

module Faraday
  module Uid2
    Faraday::Request.register_middleware uid2_encryption: Middleware
  end
end

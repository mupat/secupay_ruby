require "net/http"
require "json"
require "uri"

module SecupayRuby
  module Requests
    autoload :GetTypes, "secupay_ruby/requests/get_types"
    autoload :Init, "secupay_ruby/requests/init"
    autoload :Status, "secupay_ruby/requests/status"
    autoload :Capture, "secupay_ruby/requests/capture"
    autoload :Cancel, "secupay_ruby/requests/cancel"
    autoload :RequestApiKey, "secupay_ruby/requests/request_api_key"

    class Base
      class << self
        def post(api_key: , payment: nil, body: {})
          new(api_key: api_key,
              payment: payment,
              body: body).post
        end
      end

      attr_reader :payment, :body

      def initialize(api_key: , payment: nil, body: {})
        @api_key = api_key
        @payment = payment
        @body = body
      end

      def post
        http_response
      end

      def uri
        @uri ||= URI.parse([SecupayRuby.config.host, path].join("/"))
      end

      def path
        raise NotImplementedError.new "Abstract method!"
      end

      def defaults
        {
          apikey: @api_key.key
        }
      end

      def http_request
        @request ||= begin
          request = Net::HTTP::Post.new(uri.request_uri,
                                        {
                                          "Content-Type" => "application/json; charset=utf-8;",
                                          "Accept" => "application/json;"
                                        })

          request.body = { data: defaults.merge(body) }.to_json

          request
        end
      end

      Response = Struct.new(:http_status, :status, :data, :errors)

      def http_response
        @response ||= begin
          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(http_request)
          end

          json_response = JSON.parse(response.body)

          Response.new(response.header.code,
                       json_response["status"],
                       json_response["data"],
                       json_response["errors"])
        end
      end
    end
  end
end

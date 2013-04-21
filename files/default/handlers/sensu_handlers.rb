require 'uri'
require 'net/http'
require 'json'

class Chef
  class Handler
    class Sensu

      class API
        def initialize(api)
          @uri = URI.parse(api)
        end

        def silence_client(client)
          req = Net::HTTP::Post.new("/stash/silence/#{client}", {'Content-Type' => 'application/json'})
          payload = { 'timestamp' => Time.now.to_i, 'owner' => 'chef' }.to_json
          req.body = payload

          begin
            Net::HTTP.start(@uri.host, @uri.port) do |http|
              http.request(req)
            end
          rescue StandardError, Timeout::Error => e
            Chef::Log.error("Error silencing Sensu client #{client}: " + e.inspect)
          end
        end

        def unsilence_client(client)
          req = Net::HTTP::Delete.new("/stash/silence/#{client}")
          begin
            Net::HTTP.start(@uri.host, @uri.port) do |http|
              http.request(req)
            end
          rescue StandardError, Timeout::Error => e
            Chef::Log.error("Error unsilencing Sensu client #{client}: " + e.inspect)
          end
        end
      end

      class Silence < Chef::Handler
        def initialize(config={})
          @api = Chef::Handler::Sensu::API.new(config[:api])
          @client = config[:client]
        end

        def report
          Chef::Log.info("Sensu Handler: Silencing #{@client}")
          @api.silence_client(@client)
        end
      end

      class Unsilence < Chef::Handler
        def initialize(config={})
          @api = Chef::Handler::Sensu::API.new(config[:api])
          @client = config[:client]
        end

        def report
          Chef::Log.info("Sensu Handler: Unsilencing #{@client}")
          @api.unsilence_client(@client)
        end
      end
    end
  end
end

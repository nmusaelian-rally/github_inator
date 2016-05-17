require 'uri'
require 'base64'
require 'json'
require 'pp'
require 'uri'
require 'faraday'
require 'yaml'
require 'inator'

module GithubInator

  class GithubConnector
    attr_reader :current_user, :connection, :request, :response
    def initialize(config)
      @current_user = config['user']
      @connection = Inator::Connector.new(config)
    end

    def make_request(method, endpoint, options={}, data=nil, extra_headers=nil)
      @request = GithubInator::GithubRequest.new(method,
                                               endpoint,
                                               options,
                                               data,
                                               extra_headers)
      @request.execute_request(@connection)
    end
  end

end











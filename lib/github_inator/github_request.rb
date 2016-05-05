module GithubInator

  class GithubRequest
    attr_accessor :method, :endpoint, :options, :data, :extra_headers
    attr_reader   :response
    def initialize(method, endpoint, options={}, data=nil, extra_headers=nil)
      @method         = method
      @endpoint       = endpoint
      @options        = options
      @data           = data
      @extra_headers  = extra_headers
      @response = nil
    end

    def execute_request(connection)
      status, headers, body = connection.make_request(@method,
                                              @endpoint,
                                              @options,
                                              @data,
                                              @extra_headers)

      @response = GithubInator::GithubResponse.new(status, headers, body)
      return @response
    end
  end

end











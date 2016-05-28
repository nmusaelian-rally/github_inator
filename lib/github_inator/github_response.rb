module GithubInator

  class GithubResponse
    attr_reader :headers, :status, :body, :next
    def initialize(status, headers, body)
      @status     = status
      @headers    = headers
      @body       = JSON.parse(body)
      link      = headers.has_key?("Link") ? headers["Link"] : nil
      if link && link.include?("rel=\"next\"")
        @next = get_next(link)
      else
        @next = nil
      end
    end

    def get_next(link)
      link.split(', ').map {|e| e.split('; ')}.find {|e| e[1] == 'rel="next"'}[0][1..-2]
    end
 end
end











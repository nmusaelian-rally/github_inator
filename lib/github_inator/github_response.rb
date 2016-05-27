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
      pattern = /<.*>; rel="next"/
      match_data = link.match(pattern)
      puts "match_data: #{match_data.to_s}"
      narrow_pattern = /<(.*)>/
      url = match_data.to_s.match(narrow_pattern)

      url = url.to_s
      url = url[1..-2] #remove angle brackets
      return url
    end
 end
end











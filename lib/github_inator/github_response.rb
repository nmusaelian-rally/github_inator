module GithubInator

  class GithubResponse
    attr_reader :header, :status, :body, :links
    def initialize(headers, body)
      @headers    = headers
      @status     = headers['Status']
      @body       = JSON.parse(body)
      @links      = headers.has_key?("Link") ? headers["Link"] : nil
      if headers.has_key?("Link")
        @links = get_links
      else
        @links = nil
      end

    end

    def get_links
      possible_pointers = ['first', 'next', 'prev', 'last']
      links = {}
      possible_pointers.each do |pointer|
        if @links.include?("rel=\"#{pointer}\"") # e.g rel="last"
          page = get_page_number(pointer)
          links[pointer] = page
        end
      end
      puts "LINK: #{links}" #e.g. when page-2, {"first"=>1, "next"=>3, "prev"=>1, "last"=>22}
      return links
    end

    def get_page_number(pointer)
      pattern = /page=\d+>; rel="#{pointer}"/
      match_data = @links.match(pattern) #instance of MatchData
      narrow_pattern = /\d+/
      page = match_data.to_s.match(narrow_pattern)
      return page.to_s.to_i
    end
  end

end











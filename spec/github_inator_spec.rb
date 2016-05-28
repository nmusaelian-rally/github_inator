require 'github_inator'
require 'time'
#require 'spec_helpers/connector_runner'

ORG_REPOS_ENDPOINT = "orgs/<org_name>/repos"
REPO_COMMITS_ENDPOINT = "repos/<org_name>/<repo_name>/commits"

describe GithubInator do
  before :each do
    @connector = GithubInator::GithubConnector.new(YAML.load_file('./spec/configs/github.yml'))
  end

  describe "#make_request" do
    context "check for links" do
      before :each do
        organization = "RallyCommunity"
        @repos_endpoint = ORG_REPOS_ENDPOINT.sub('<org_name>', organization)
      end
      it "response header includes links when there is more than one page of results" do
        response = @connector.make_request(:get, @repos_endpoint)
        expect(response).to be_an_instance_of GithubInator::GithubResponse
        expect(response.status).to eql(200)
        expect(response.next).to_not be_nil
      end
      it "response header includes next link equal 3 if page 2 is requested" do
        page = {page: 2}
        response = @connector.make_request(:get, @repos_endpoint, page)
        expect(response.next[-1]) == "3"
      end
    end
    context "limit queries by time" do
      before :each do
        organization = "RallyCommunity"
        repo = "open-closed-defects-chart"
        replacements = {'<org_name>' => organization, '<repo_name>' => repo}
        @repo_commits_endpoint = REPO_COMMITS_ENDPOINT.gsub(/<\w+>/) {|match| replacements.fetch(match,match)}
        puts @repo_commits_endpoint
      end
      it "limit results by date" do
        since = {since: '2015-03-01'}
        response = @connector.make_request(:get, @repo_commits_endpoint, since)
        results = response.body
        expect(results.length).to eql(2)
      end
      it "limit results by date and time" do
        since =  {since: '2015-03-24T13:44:10Z'}
        response = @connector.make_request(:get, @repo_commits_endpoint, since)
        results = response.body
        expect(results.length).to eql(1)
      end
      it "use two parameters" do
        str1 = '2014-10-01T00:00:00Z'
        str2 = '2015-03-04T00:00:00Z'
        t1 = Time.parse(str1)
        t2 = Time.parse(str2)
        parameters =  {since: str1, until: str2}
        response = @connector.make_request(:get, @repo_commits_endpoint, parameters)
        results = response.body
        expect(results.length).to eql(2)
        expect(Time.parse(results.first["commit"]["author"]["date"])).to be_between(t1, t2)
        expect(Time.parse(results.last["commit"]["author"]["date"])).to be_between(t1, t2)
      end
    end
    context "page" do
      before :each do
        organization = "RallyCommunity"
        repo = "rally-java-rest-apps"
        replacements = {'<org_name>' => organization, '<repo_name>' => repo}
        @repo_commits_endpoint = REPO_COMMITS_ENDPOINT.gsub(/<\w+>/) {|match| replacements.fetch(match,match)}
      end
      it "get urls" do
        response1 = @connector.make_request(:get, @repo_commits_endpoint)
        expect(response1.next).to be == "https://api.github.com/repositories/29268324/commits?page=2"
        response2 = @connector.make_request(:get, response1.next)
        expect(response2.next).to be == "https://api.github.com/repositories/29268324/commits?page=3"
        response3 = @connector.make_request(:get, response2.next)
        puts response3.body.length
        expect(response3.next).to be_nil
      end
      it "get urls when query limited by date" do
        since =  {since: '2015-01-01'}
        response1 = @connector.make_request(:get, @repo_commits_endpoint, since)
        expect(response1.next).to be == "https://api.github.com/repositories/29268324/commits?since=2015-01-01&page=2"
        response2 = @connector.make_request(:get, response1.next)
        puts response2.body.length
        expect(response2.next).to be_nil
      end
      it "page while next is not null" do
        total_results = []
        total_results_count = 0
        response = @connector.make_request(:get, @repo_commits_endpoint)
        total_results << response.body
        total_results_count += response.body.length
        while response.next != nil do
          response = @connector.make_request(:get, response.next)
          total_results << response.body
          total_results_count += response.body.length
        end
        expect(total_results_count).to be >= 87
        expect(total_results.flatten.length).to be == total_results_count
      end
    end
  end
end
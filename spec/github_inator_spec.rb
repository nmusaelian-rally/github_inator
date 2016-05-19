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
    context "pagination" do
      before :each do
        organization = "RallyCommunity"
        @repos_endpoint = ORG_REPOS_ENDPOINT.sub('<org_name>', organization)
      end
      it "return links if there is more than one page of results" do
        response = @connector.make_request(:get, @repos_endpoint)
        expect(response).to be_an_instance_of GithubInator::GithubResponse
        expect(response.status).to eql(200)
        expect(response.links.length).to eql(2)
        expect(response.links.has_key?("next")).to be true
        expect(response.links.has_key?("last")).to be true
      end
      it "response includes next link equal 3 if page 2 is requested" do
        page = {page: 2}
        response = @connector.make_request(:get, @repos_endpoint, page)
        expect(response.links["next"]).to eq(3)
      end
      it "response includes prev link equal 2 if page 3 is requested" do
        page = {'page': 3}
        response = @connector.make_request(:get, @repos_endpoint, page)
        expect(response.links["prev"]).to eq(2)
      end
    end
    context "time based queries" do
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
  end
end
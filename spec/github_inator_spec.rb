require 'github_inator'
require 'time'
#require 'spec_helpers/connector_runner'

ORG_REPOS_ENDPOINT = "orgs/<org_name>/repos"
REPO_COMMITS_ENDPOINT = "repos/<org_name>/<repo_name>/commits"

# List teams in organization
ORGS_TEAMS_ENDPOINT = "orgs/<org_name>/teams"

# List all of the teams across all of the organizations to which the authenticated user belongs.
USER_TEAMS_ENDPOINT = "user/teams"

TEAM_REPOS_ENDPOINT = "teams/<id>/repos"


def get_all_results(connector, method, endpoint, options={}, data=nil, extra_headers=nil)
  total_results = []
  response = @connector.make_request(method, endpoint,options,data,extra_headers)
  total_results << response.body
  while response.next != nil do
    response = @connector.make_request(:get, response.next)
    total_results << response.body
  end
  total_results
end

describe GithubInator do
  before :all do
    @repositories = []
  end
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
        results = get_all_results(@connector, :get, @repo_commits_endpoint).flatten
        expect(results.length).to be >= 87
        fewer_results = get_all_results(@connector, :get, @repo_commits_endpoint, since: "2015-01-01").flatten
        expect(fewer_results.length).to be < results.length
      end
      it "these endpoints should not return same results" do
        endpoint1 = "https://api.github.com/repositories/29268324/commits?page=2"
        endpoint2 = "https://api.github.com/repositories/29268324/commits?since=2015-01-01&page=2"
        result1 = get_all_results(@connector, :get, endpoint1).flatten
        result2 = get_all_results(@connector, :get, endpoint2).flatten
        puts "result1 length: #{result1.length}, result2 length: #{result2.length}"
        expect(result1.length).to be > result2.length
      end
      it "these endpoints should return same two pages" do
        endpoint1 = "https://api.github.com/repositories/29268324/commits?since=2015-01-01"
        endpoint2 = "https://api.github.com/repos/RallyCommunity/rally-java-rest-apps/commits?since=2015-01-01"
        result1 = get_all_results(@connector, :get, endpoint1)
        result2 = get_all_results(@connector, :get, endpoint2)
        puts "result1 num of pages: #{result1.length}, result2 num of pages: #{result2.length}"
        expect(result1.length).to be == result2.length
        puts "result1 total result count: #{result1.flatten.length}, result2 total result count: #{result2.flatten.length}"
        expect(result1.flatten.length).to be == result2.flatten.length
      end
    end
    context "teams, repos, commits" do
      before :each do
        @organization = "RallySoftware"
        @org_teams_endpoint = ORGS_TEAMS_ENDPOINT.sub('<org_name>', @organization)
      end
      it "get organization's teams and user's teams" do
        teams = []
        user_teams = get_all_results(@connector, :get, USER_TEAMS_ENDPOINT).flatten
        puts "I am a member of #{user_teams.length} teams"
        org_teams = get_all_results(@connector, :get, @org_teams_endpoint).flatten
        puts "There are #{org_teams.length} teams in #{@organization} organization"
        expect(user_teams.flatten.length).to be < org_teams.flatten.length
        user_teams.each do |team|
            teams << {name: team['name'], id: team['id'], organization: team['organization']['login']}
        end
        lookback = 600 #86400
        now = Time.new.utc
        back = now - lookback
        since = {since: back.iso8601}
        repositories_with_recent_commits = []
        teams.each do |team|
          puts "getting repos for team: #{team}"
          team_repos_endpoint = TEAM_REPOS_ENDPOINT.sub('<id>', team[:id].to_s)
          team_repos = get_all_results(@connector, :get, team_repos_endpoint).flatten
          team_repos.each do |repo|
            replacements = {'<org_name>' => repo['owner']['login'], '<repo_name>' => repo['name']}
            repo_commits_endpoint = REPO_COMMITS_ENDPOINT.gsub(/<\w+>/) {|match| replacements.fetch(match,match)}
            commits = get_all_results(@connector, :get, repo_commits_endpoint, since).flatten
            if commits.length > 0
              repositories_with_recent_commits << repo['name']
              puts "found #{commits.length} commits in #{repo['name']} repo since #{since} "
            end
          end
        end
      end
    end
  end
end
require 'github_inator'
require 'spec_helpers/connector_runner'

ORG_REPOS_ENDPOINT = "orgs/<org_name>/repos"

describe GithubInator do
  before :each do
    @connector = GithubInator::GithubConnector.new(YAML.load_file('./spec/configs/github.yml'))
  end

  describe "#make_request" do
    it "return links if there is more than one page of results" do
      organization = "RallyCommunity"
      repos_endpoint = ORG_REPOS_ENDPOINT.sub('<org_name>', organization)
      response = @connector.make_request(:get, repos_endpoint)
      expect(response).to be_an_instance_of GithubInator::GithubResponse
      expect(response.status).to eql(200)
      expect(response.links.length).to eql(2)
      expect(response.links.has_key?("next")).to be true
      expect(response.links.has_key?("last")).to be true
    end
    it "limit results by date and time" do
      since1 = {since: '2015-03-01'}
      since2 =  {since: '2015-03-24T13:44:10Z'}
      endpoint = "repos/RallyCommunity/open-closed-defects-chart/commits"
      response1 = @connector.make_request(:get, endpoint, since1)
      expect(response1.status).to eql(200)
      results1 = response1.body
      expect(results1.length).to eql(2)
      response2 = @connector.make_request(:get, endpoint, since2)
      expect(response2.status).to eql(200)
      results2 = response2.body
      expect(results2.length).to eql(1)
    end
  end
end
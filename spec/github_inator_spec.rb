require 'github_inator'

ORGS_REPO_ENDPOINT = "orgs/<org_name>/repos"

describe GithubInator do
  before :each do
    @connector = GithubInator::GithubConnector.new(YAML.load_file('./spec/configs/github.yml'))
  end
  describe "#new" do
    it "returns a Connector object" do
        expect(@connector).to be_an_instance_of GithubInator::GithubConnector
    end
  end
  describe "#make_request" do
    context "given organization RallyCommunity" do
      it "make_request returns status 200" do
        organization = "RallyCommunity"
        repos_endpoint = ORGS_REPO_ENDPOINT.sub('<org_name>', organization)
        response = @connector.make_request(:get, repos_endpoint)
        expect(response).to be_an_instance_of GithubInator::GithubResponse
        expect(response.status).to eql(200)
        results = response.body
        expect(results.length).to be > 0
      end
    end
  end
end
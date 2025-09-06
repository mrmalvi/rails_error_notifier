require "spec_helper"
require "rails_error_notifier/middleware"
require "rack/test"
require "webmock/rspec"

RSpec.describe RailsErrorNotifier::Middleware do
  include Rack::Test::Methods

  let(:exception) { StandardError.new("Something went wrong") }

  before do
    RailsErrorNotifier.configure do |config|
      config.slack_webhook = "http://example.com/slack"
      config.discord_webhook = "http://example.com/discord"
      config.enabled = true
    end

    stub_request(:post, "http://example.com/slack").to_return(status: 200)
    stub_request(:post, "http://example.com/discord").to_return(status: 200)
  end

  let(:app) do
    Rack::Builder.new do
      use RailsErrorNotifier::Middleware
      run ->(_env) { [200, {}, ["OK"]] }
    end.to_app
  end

  it "calls the next app normally" do
    get "/test", {}, "rack.test" => true
    expect(last_response.status).to eq(200)
  end

  it "notifies on exceptions" do
    failing_app = ->(_env) { raise exception }
    middleware = RailsErrorNotifier::Middleware.new(failing_app)

    expect { middleware.call("PATH_INFO" => "/fail") }.to raise_error(StandardError)
    expect(a_request(:post, "http://example.com/slack")).to have_been_made
    expect(a_request(:post, "http://example.com/discord")).to have_been_made
  end
end

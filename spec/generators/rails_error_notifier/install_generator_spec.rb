# spec/generators/rails_error_notifier/install_generator_spec.rb
require_relative "../../../lib/generators/rails_error_notifier/install_generator"

RSpec.describe RailsErrorNotifier::Generators::InstallGenerator, type: :generator do
  let(:destination_root) { File.expand_path("../../../tmp/generator_test_app", __dir__) }
  let(:initializer_path) { File.join(destination_root, "config/initializers/rails_error_notifier.rb") }

  before do
    FileUtils.rm_rf(destination_root) # clean up
    FileUtils.mkdir_p(destination_root)

    # Run the generator with a temporary destination root
    Dir.chdir(destination_root) do
      described_class.start
    end
  end

  it "creates the initializer file" do
    expect(File).to exist(initializer_path)
  end

  it "writes the expected content to the initializer" do
    content = File.read(initializer_path)
    expect(content).to include("RailsErrorNotifier.configure do |config|")
  end
end

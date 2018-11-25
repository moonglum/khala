RSpec.configure do |c|
  # filter_run is short-form alias for filter_run_including
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end

require "equivalent-xml"
RSpec::Matchers.define :eq_html do |expected|
  match do |actual|
    EquivalentXml.equivalent?(Nokogiri::HTML(expected), Nokogiri::HTML(actual))
  end

  failure_message do |actual|
    "expected that\n#{Nokogiri::HTML(actual)}\nwould be equal to\n#{Nokogiri::HTML(expected)}"
  end
end

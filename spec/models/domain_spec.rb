require 'spec_helper'
require_relative '../../fs_overlay/opt/certs_manager/certs_manager'

RSpec.describe Domain do
  before do
    allow(NAConfig).to receive(:stage).and_return('local')
  end

  it 'returns correct name, upstream. redirect_target_url and stage' do
    keys = [:descriptor, :name, :upstream, :redirect_target_url, :stage]

    domain_configs = [
      ['example.com', 'example.com', nil, nil, 'local'],
      [' example.com ', 'example.com', nil, nil, 'local'],
      ['example.com #staging', 'example.com', nil, nil, 'staging'],
      ['example.com -> http://target ', 'example.com', 'http://target', nil, 'local'],
      ['example.com => http://target', 'example.com', nil, 'http://target', 'local'],
      ['example.com=>http://target', 'example.com', nil, 'http://target', 'local'],
      ['example.com -> http://target #staging', 'example.com', 'http://target', nil, 'staging'],
      ['example.com => http://target #staging', 'example.com', nil, 'http://target', 'staging'],
      ['example.com->http://target #staging', 'example.com', 'http://target', nil, 'staging'],
    ]

    domain_configs.map { |config|
      Hash[keys.zip(config)]
    }.each do |config|
      domain = Domain.new(config[:descriptor])

      expect(domain.name).to eq(config[:name]), lambda { "Parsing failed on '#{config[:descriptor]}' method :name, expected #{config[:name]}, got #{domain.name}" }
      expect(domain.upstream).to eq(config[:upstream]), lambda { "Parsing failed on '#{config[:descriptor]}' method :upstream, expected #{config[:upstream]}, got #{domain.upstream}" }
      expect(domain.redirect_target_url).to eq(config[:redirect_target_url]), lambda { "Parsing failed on '#{config[:descriptor]}' method :redirect_target_url, expected #{config[:redirect_target_url]}, got #{domain.redirect_target_url}" }
      expect(domain.stage).to eq(config[:stage]), lambda { "Parsing failed on '#{config[:descriptor]}' method :stage, expected #{config[:stage]}, got #{domain.stage}" }
    end
  end
end

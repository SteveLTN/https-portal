require 'spec_helper'
require_relative '../../fs_overlay/opt/certs_manager/certs_manager'

RSpec.describe Domain do
  before do
    allow(NAConfig).to receive(:stage).and_return('local')
    allow(FileUtils).to receive(:mkdir_p)
  end

  it 'returns correct names, upstream. redirect_target_url, stage etc.' do
    keys = [:descriptor, :name, :env_name, :upstream_proto, :upstreams, :redirect_target_url, :stage, :basic_auth_username, :basic_auth_password, :access_restriction]

    domain_configs = [
      ['example.com', 'example.com', 'EXAMPLE_COM', nil, [], nil, 'local', nil, nil, nil],
      ['4example.com', '4example.com', '4EXAMPLE_COM', nil, [], nil, 'local', nil, nil, nil],
      [' example.com ', 'example.com', 'EXAMPLE_COM', nil, [], nil, 'local', nil, nil, nil],
      ['example.com #staging', 'example.com', 'EXAMPLE_COM', nil, [], nil, 'staging', nil, nil, nil],
      ['example.com -> http://target ', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'local', nil, nil, nil],
      ["example.com \n-> http://target \n", 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'local', nil, nil, nil],
      ["example.com\n-> http://target ", 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'local', nil, nil, nil],
      ['example.com -> http://target:8000', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target:8000', :parameters => nil}], nil, 'local', nil, nil, nil],
      ['example.com -> target:8000', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target:8000', :parameters => nil}], nil, 'local', nil, nil, nil],
      ['example.com => http://target', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], 'http://target', 'local', nil, nil, nil],
      ['example.com => https://target', 'example.com', 'EXAMPLE_COM', 'https://', [{:address => 'target', :parameters => nil}], 'https://target', 'local', nil, nil, nil],
      ['example.com => target', 'example.com', 'EXAMPLE_COM', 'https://', [{:address => 'target', :parameters => nil}], 'https://target', 'local', nil, nil, nil],
      ['example.com=>http://target', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], 'http://target', 'local', nil, nil, nil],
      ['example.com -> http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', nil, nil, nil],
      ['example.com => http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], 'http://target', 'staging', nil, nil, nil],
      ['example.com->http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', nil, nil, nil],
      ['exam-ple.com->http://tar-get #staging', 'exam-ple.com', 'EXAM_PLE_COM', 'http://', [{:address => 'tar-get', :parameters => nil}], nil, 'staging', nil, nil, nil],
      ['example_.com->http://target #staging', 'example_.com', 'EXAMPLE__COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', nil, nil, nil],
      ['example.com->http://tar_get_ #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'tar_get_', :parameters => nil}], nil, 'staging', nil, nil, nil],
      ['username:password@example.com', 'example.com', 'EXAMPLE_COM', nil, [], nil, 'local', 'username', 'password', nil],
      ['username:password@example.com -> http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', 'username', 'password', nil],
      ['[1.2.3.4/24]username:password@example.com -> http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', 'username', 'password', %w(1.2.3.4/24)],
      [' [ 1.2.3.4 4.3.2.1/24 ] username:password@example.com -> http://target #staging', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target', :parameters => nil}], nil, 'staging', 'username', 'password', %w(1.2.3.4 4.3.2.1/24)],
      ['example.com -> https://target1|target2:8000', 'example.com', 'EXAMPLE_COM', 'https://', [{:address => 'target1', :parameters => nil}, {:address => 'target2:8000', :parameters => nil}], nil, 'local', nil, nil, nil],
      ['example.com -> http://target1:8000|target2:8001[backup max_conns=100]', 'example.com', 'EXAMPLE_COM', 'http://', [{:address => 'target1:8000', :parameters => nil}, {:address => 'target2:8001', :parameters => 'backup max_conns=100'}], nil, 'local', nil, nil, nil],
    ]

    domain_configs.map { |config|
      Hash[keys.zip(config)]
    }.each do |config|
      domain = Domain.new(config[:descriptor])

      expect(domain.name).to eq(config[:name]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :name, expected #{config[:name].inspect}, got #{domain.name.inspect}" }
      expect(domain.env_name).to eq(config[:env_name]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :env_name, expected #{config[:env_name].inspect}, got #{domain.env_name.inspect}" }
      expect(domain.upstream_proto).to eq(config[:upstream_proto]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :upstream_proto, expected #{config[:upstream_proto].inspect}, got #{domain.upstream_proto.inspect}" }
      expect(domain.upstreams).to eq(config[:upstreams]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :upstreams, expected #{config[:upstreams].inspect}, got #{domain.upstreams.inspect}" }
      expect(domain.redirect_target_url).to eq(config[:redirect_target_url]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :redirect_target_url, expected #{config[:redirect_target_url].inspect}, got #{domain.redirect_target_url.inspect}" }
      expect(domain.stage).to eq(config[:stage]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :stage, expected #{config[:stage].inspect}, got #{domain.stage.inspect}" }
      expect(domain.basic_auth_username).to eq(config[:basic_auth_username]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :basic_auth_username, expected #{config[:basic_auth_username].inspect}, got #{domain.basic_auth_username.inspect}" }
      expect(domain.basic_auth_password).to eq(config[:basic_auth_password]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :basic_auth_password, expected #{config[:basic_auth_password].inspect}, got #{domain.basic_auth_password.inspect}" }
      expect(domain.access_restriction).to eq(config[:access_restriction]), lambda { "Parsing failed on #{config[:descriptor].inspect} method :access_restriction, expected #{config[:access_restriction].inspect}, got #{domain.access_restriction.inspect}" }
    end
  end
end

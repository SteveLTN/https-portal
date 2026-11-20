require 'spec_helper'

RSpec.describe 'Minimal setup', composition: 'minimal-setup', type: :feature do
  context 'when no certificates are stored' do
    it 'should use patched Ruby and serve a welcome page' do
      docker_compose :up, env: { 'FORCE_RENEW' => 'true' }

      ruby_version = `docker-compose --project-name portalspec exec -T https-portal /usr/bin/ruby -e 'print RUBY_VERSION'`
      expect(ruby_version).to eq '3.3.14'

      page = read_https_content
      expect(page).to include 'Welcome to HTTPS-PORTAL!'
    end
  end

  context 'when certificates are stored in a data volume' do
    it 'should serve a welcome page' do
      docker_compose :up

      page = read_https_content
      expect(page).to include 'Welcome to HTTPS-PORTAL!'
    end
  end
end

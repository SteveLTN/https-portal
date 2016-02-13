require 'spec_helper'

RSpec.describe 'Minimal setup', composition: 'minimal-setup' do
  context 'when no certificates are stored' do
    it 'should serve a welcome page' do
      docker_compose :up, env: { 'FORCE_RENEW' => 'true' }

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

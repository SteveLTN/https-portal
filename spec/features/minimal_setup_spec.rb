require 'spec_helper'

RSpec.describe 'Minimal setup' do
  around :each do |example|
    Dir.chdir CompositionsPath.join('minimal-setup') do
      example.run
    end
  end

  context 'when no certificates are stored' do
    it 'should serve a welcome page' do
      system({ 'TEST_DOMAIN' => TEST_DOMAIN, 'FORCE_RENEW' => 'true' }, 'docker-compose up -d')

      page = read_https_content
      expect(page).to include 'Welcome to HTTPS-PORTAL!'
    end
  end

  context 'when certificates are stored in a data volume' do
    it 'should serve a welcome page' do
      system({ 'TEST_DOMAIN' => TEST_DOMAIN }, 'docker-compose stop && docker-compose up -d')

      page = read_https_content
      expect(page).to include 'Welcome to HTTPS-PORTAL!'
    end
  end
end

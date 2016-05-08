require 'spec_helper'

RSpec.describe 'Auto discovery', composition: 'auto-discovery', type: :feature do
  context 'when no certificates are stored' do
    it 'should forward request to auto discovered WordPress container' do
      docker_compose :up, env: { 'FORCE_RENEW' => 'true' }

      page = read_https_content
      expect(page).to include 'WordPress'
    end
  end

  context 'when certificates are stored in a data volume' do
    it 'should forward request to auto discovered WordPress container' do
      docker_compose :up

      page = read_https_content
      expect(page).to include 'WordPress'
    end
  end
end

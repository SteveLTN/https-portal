require 'spec_helper'

# This spec intentionally reuse containers created by previous example group.
# Since we don't retry the docker command here, to ensure it success, an
# already initialized https-portal instance is required.
RSpec.describe 'Renewal', :reuse_container, composition: 'minimal-setup' do

  let(:docker_command) { 'docker exec portalspec_https-portal_1 bash -c ' +
                         "'test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )'" }

  context 'when certs already signed and no FORCE_RENEW specified' do
    it 'should not renew certs' do
      docker_compose :up

      read_https_content
      output = `#{docker_command}`

      expect(output).to include "No need to renew certs for #{ENV['TEST_DOMAIN']}"
    end
  end

  context 'when certs already signed and FORCE_RENEW specified' do
    it 'should force renew the certs' do
      docker_compose :up, env: { 'FORCE_RENEW' => 'true' }

      read_https_content
      output = `#{docker_command}`

      expect(output).to include "Renewed certs for #{ENV['TEST_DOMAIN']}"
    end
  end
end

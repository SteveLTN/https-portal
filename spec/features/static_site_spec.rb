require 'spec_helper'

RSpec.describe 'Serving static site', composition: 'static-site' do
  before :all do
    system 'docker-machine ssh $DOCKER_MACHINE_NAME rm -rf /data/https-portal'
  end

  it 'should serve a custom index page' do
    docker_compose :up
    system "docker-machine scp index.html $DOCKER_MACHINE_NAME:/data/https-portal/vhosts/#{ENV['TEST_DOMAIN']}/"

    page = read_https_content
    expect(page).to include 'Welcome to my awesome static site powered by HTTPS-PORTAL!'
  end

  it 'should serve a custom page' do
    docker_compose :up
    system "docker-machine scp index.html $DOCKER_MACHINE_NAME:/data/https-portal/vhosts/#{ENV['TEST_DOMAIN']}/welcome"

    page = read_https_content('welcome')
    expect(page).to include 'Welcome to my awesome static site powered by HTTPS-PORTAL!'
  end
end

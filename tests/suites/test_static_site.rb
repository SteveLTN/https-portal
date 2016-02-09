require "minitest/autorun"
require_relative "../test_helper"

class TestStaticSites < Minitest::Test
  def setup
    system <<-BASH
      docker-machine ssh $DOCKER_MACHINE_NAME rm -rf /data/https-portal
    BASH
  end

  def test_static_site
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/static-site/ && docker-compose up -d")

    page = read_https_content
    assert page.include?("Welcome to HTTPS-PORTAL!")

    system <<-BASH
      cd ./compositions/static-site/ &&
      docker-machine scp index.html $DOCKER_MACHINE_NAME:/data/https-portal/vhosts/#{TEST_DOMAIN}/
    BASH

    page = read_https_content
    assert page.include?("Welcome to my awesome static site powered by HTTPS-PORTAL!")
  end

  def teardown
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/static-site/ && docker-compose stop")
  end
end

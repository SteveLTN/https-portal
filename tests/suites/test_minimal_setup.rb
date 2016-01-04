require "minitest/autorun"
require_relative "../test_helper"

class TestMinimalSetup < Minitest::Test
  def setup
    cleanup_docker_machine
  end

  def test_auto_discovery
    # When no certificates are stored
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/minimal-setup/ && docker-compose build && docker-compose up -d")

    page = read_https_content
    assert page.include?("Welcome to HTTPS-PORTAL!")

    # When certificates are stored in a data volume
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/minimal-setup/ && docker-compose build && docker-compose up -d")

    page = read_https_content
    assert page.include?("Welcome to HTTPS-PORTAL!")
  end

  def teardown
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/minimal-setup/ && docker-compose stop")
  end
end

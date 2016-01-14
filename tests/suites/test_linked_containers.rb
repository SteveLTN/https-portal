require "minitest/autorun"
require_relative "../test_helper"

class TestLinkedContainers < Minitest::Test
  def test_linked_containers
    # When no certificates are stored
    system({ "TEST_DOMAIN" => TEST_DOMAIN, "FORCE_RENEW" => "true" }, "cd ./compositions/linked-containers/ && docker-compose up -d")

    page = read_https_content
    assert page.include?("WordPress")

    # When certificates are stored in a data volume
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/linked-containers/ && docker-compose stop && docker-compose up -d")

    page = read_https_content
    assert page.include?("WordPress")
  end

  def teardown
    system({ "TEST_DOMAIN" => TEST_DOMAIN }, "cd ./compositions/linked-containers/ && docker-compose stop")
  end
end

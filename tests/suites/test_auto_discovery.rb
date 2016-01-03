require "minitest/autorun"
require_relative "../test_helper"

class TestAutoDiscovery < Minitest::Test
  def setup
    cleanup_docker_machine
  end

  def test_auto_discovery
    # When no certificates are stored
    `cd ./compositions/auto-discovery/ && docker-compose build && docker-compose up -d`

    page = read_https_content
    assert page.include?("WordPress")

    # When certificates are stored in a data volume
    `cd ./compositions/auto-discovery/ && docker-compose build && docker-compose up -d`

    page = read_https_content
    assert page.include?("WordPress")
  end

  def teardown
    `cd ./compositions/auto-discovery/ && docker-compose stop`
  end
end

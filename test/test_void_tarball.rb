# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
# require 'minitest/pride' # Optional: adds colorful output to your tests
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'net/http'
require 'uri'

# ==============================================================================
# STUBS: Isolate the class from external dependencies
# ==============================================================================
module Getch
  # Match the structure of the real OPTIONS hash (unfrozen, so we can modify it in tests)
  OPTIONS = { mountpoint: '/tmp/getch_test_mount', musl: false }

  class Log
    attr_reader :info_messages, :fatal_message, :result_ok_count

    def initialize(verbose: false)
      @info_messages = []
      @fatal_message = nil
      @result_ok_count = 0
    end

    def info(msg)
      @info_messages << msg
    end

    def result_ok
      @result_ok_count += 1
    end

    def fatal(msg)
      @fatal_message = msg
      raise "FATAL: #{msg}" # Raise to halt execution, mimicking the real exit 1 behavior
    end
  end

  module Helpers
    class << self
      attr_accessor :mock_get_file_online

      def get_file_online(url, dest)
        if mock_get_file_online
          mock_get_file_online.call(url, dest)
        else
          File.write(dest, 'mocked content')
        end
      end
    end
  end
end

# ==============================================================================
# REQUIRE: Load the actual class under test
# Adjust the relative path based on where you save this test file
# ==============================================================================
require_relative '../lib/getch/void/tarball'

# ==============================================================================
# TESTS
# ==============================================================================
class TestGetchVoidTarball < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    Getch::OPTIONS[:mountpoint] = @tmpdir
    Getch::OPTIONS[:musl] = false
    Getch::Helpers.mock_get_file_online = nil

    @tarball = Getch::Void::Tarball.new
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if File.exist?(@tmpdir)
    Getch::Helpers.mock_get_file_online = nil
  end

  # --- Initialization ---
  def test_initialize_sets_instance_variables_and_changes_directory
    tarball = Getch::Void::Tarball.new
    assert_instance_of Getch::Log, tarball.instance_variable_get(:@log)
    assert_equal 'https://repo-default.voidlinux.org/live/current', tarball.instance_variable_get(:@url)
    assert_equal 'sha256sum.txt', tarball.instance_variable_get(:@file)
    assert_equal false, tarball.instance_variable_get(:@xbps)
    assert_equal @tmpdir, Dir.pwd
  end

  # --- Protected: #tarball ---
  def test_tarball_method_returns_musl_regex_when_musl_is_true
    Getch::OPTIONS[:musl] = true
    regex = @tarball.send(:tarball)

    # Test that the regex correctly matches a musl tarball name
    assert_match regex, 'void-x86_64-musl-ROOTFS-20210930.tar.xz'
    # And ensure it does NOT match the glibc version
    refute_match regex, 'void-x86_64-ROOTFS-20210930.tar.xz'
  end

  def test_tarball_method_returns_glibc_regex_when_musl_is_false
    Getch::OPTIONS[:musl] = false
    regex = @tarball.send(:tarball)

    # Test that the regex correctly matches a glibc tarball name
    assert_match regex, 'void-x86_64-ROOTFS-20210930.tar.xz'
    # And ensure it does NOT match the musl version
    refute_match regex, 'void-x86_64-musl-ROOTFS-20210930.tar.xz'
  end

  # --- Protected: #search_archive ---
  def test_search_archive_finds_valid_archive
    sha256_content = "SHA256 (void-x86_64-ROOTFS-20210930.tar.xz) = 8681b060e39e173682e1721a6088280c2b6eade628f5e5e3e8e4b74163d187f6\n"

    Getch::Helpers.mock_get_file_online = ->(_url, dest) { File.write(dest, sha256_content) }

    result = @tarball.send(:search_archive)
    assert_equal ['SHA256', 'void-x86_64-ROOTFS-20210930.tar.xz', '=', '8681b060e39e173682e1721a6088280c2b6eade628f5e5e3e8e4b74163d187f6'],
                 result
  end

  def test_search_archive_raises_when_no_matching_line_exists
    sha256_content = "SHA256 (some-other-file.tar.xz) = 1234567890\n"
    Getch::Helpers.mock_get_file_online = ->(_url, dest) { File.write(dest, sha256_content) }

    assert_raises(RuntimeError) do
      @tarball.send(:search_archive)
    end
  end

  # --- Protected: #download ---
  def test_download_skips_if_file_already_exists
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'void-x86_64-ROOTFS-20210930.tar.xz', '=', 'hash'])
    test_file = File.join(@tmpdir, 'void-x86_64-ROOTFS-20210930.tar.xz')
    File.write(test_file, 'existing content')

    call_log = []
    Getch::Helpers.mock_get_file_online = ->(url, dest) { call_log << { url: url, dest: dest } }

    @tarball.send(:download)
    assert_empty call_log, 'Expected get_file_online not to be called'
  end

  def test_download_downloads_if_file_does_not_exist
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'void-x86_64-ROOTFS-20210930.tar.xz', '=', 'hash'])

    call_log = []
    Getch::Helpers.mock_get_file_online = lambda { |url, dest|
      call_log << { url: url, dest: dest }
      File.write(dest, 'downloaded content')
    }

    @tarball.send(:download)

    assert_equal 1, call_log.length
    assert_equal 'https://repo-default.voidlinux.org/live/current/void-x86_64-ROOTFS-20210930.tar.xz', call_log[0][:url]
  end

  def test_download_raises_fatal_if_no_xbps_file_found
    @tarball.instance_variable_set(:@xbps, false)

    assert_raises(RuntimeError) do
      @tarball.send(:download)
    end

    log = @tarball.instance_variable_get(:@log)
    assert log.fatal_message&.include?('No file found')
  end

  # --- Protected: #checksum ---
  def test_checksum_succeeds_on_valid_hash
    empty_sha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'test.tar.xz', '=', empty_sha256])
    File.write(File.join(@tmpdir, 'test.tar.xz'), '')

    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Open3.stub :capture3, ['', '', mock_status] do
      @tarball.send(:checksum)
    end

    log = @tarball.instance_variable_get(:@log)
    assert log.result_ok_count.positive?
  end

  def test_checksum_fails_and_cleans_on_invalid_hash
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'test.tar.xz', '=', 'invalidhash'])
    File.write(File.join(@tmpdir, 'test.tar.xz'), 'some content')

    cleaning_called = false
    @tarball.define_singleton_method(:cleaning) { cleaning_called = true }

    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, false)

    Open3.stub :capture3, ['', 'sha256sum: WARNING: 1 computed checksum did NOT match', mock_status] do
      assert_raises(RuntimeError) do
        @tarball.send(:checksum)
      end
    end

    assert cleaning_called
    log = @tarball.instance_variable_get(:@log)
    assert log.fatal_message&.include?('Problem with the checksum')
  end

  # --- Private: #decompress ---
  def test_decompress_succeeds
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'test.tar.xz', '=', 'hash'])

    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, true)

    Open3.stub :capture3, ['', '', mock_status] do
      @tarball.send(:decompress)
    end

    log = @tarball.instance_variable_get(:@log)
    assert log.result_ok_count.positive?
  end

  def test_decompress_fails_and_raises_fatal
    @tarball.instance_variable_set(:@xbps, ['SHA256', 'test.tar.xz', '=', 'hash'])

    mock_status = Minitest::Mock.new
    mock_status.expect(:success?, false)

    Open3.stub :capture3, ['', 'tar: Error exit delayed from previous errors', mock_status] do
      assert_raises(RuntimeError) do
        @tarball.send(:decompress)
      end
    end

    log = @tarball.instance_variable_get(:@log)
    assert log.fatal_message&.include?('Fail to decompressing')
  end

  # --- Private: #cleaning ---
  def test_cleaning_deletes_matching_files_only
    file1 = File.join(@tmpdir, 'void-x86_64-ROOTFS-20210930.tar.xz')
    file2 = File.join(@tmpdir, 'sha256sum.txt')
    file3 = File.join(@tmpdir, 'keep_me.txt')

    File.write(file1, 'tar')
    File.write(file2, 'sum')
    File.write(file3, 'keep')

    @tarball.send(:cleaning)

    refute File.exist?(file1), 'Tarball should be deleted'
    refute File.exist?(file2), 'Checksum file should be deleted'
    assert File.exist?(file3), 'Unrelated files should be preserved'
  end

  def test_voidlinux_repo_url_returns_200_ok
    url = URI('https://repo-default.voidlinux.org/live/current/sha256sum.txt')

    # Use a HEAD request to be efficient (we only care about the status code, not the body)
    request = Net::HTTP::Head.new(url)

    response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      http.request(request)
    end

    assert_equal 200, response.code.to_i, "Expected the Void Linux repo URL to return 200 OK, but got #{response.code}"
    assert_match(%r{text/plain}, response['Content-Type'], 'Expected a text/plain content type for sha256sum.txt')
  end
end

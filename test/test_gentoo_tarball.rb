# frozen_string_literal: true

require 'minitest/autorun'
require 'stringio'
require 'tmpdir'
require 'getch'

class GentooTarballTest < Minitest::Test
  def setup
    @original_options = Getch::OPTIONS.dup
    @log = FakeLog.new
  end

  def teardown
    Getch::OPTIONS.replace(@original_options)
  end

  def test_initialize_selects_release_and_stage3_variant
    {
      false => ['systemd', 'stage3-amd64-systemd'],
      true => ['musl', 'stage3-amd64-musl']
    }.each do |musl, (variant, filename)|
      Getch::OPTIONS[:musl] = musl
      contents = "20251128T120000Z/stage3-amd64-#{variant}-20251128T120000Z.tar.xz 123\n"
      stage_url = "https://mirror.rackspace.com/gentoo/releases/amd64/autobuilds/latest-stage3-amd64-#{variant}.txt"
      test = self

      with_stubbed_method(URI, :open, lambda { |url, &block|
        test.assert_equal stage_url, url
        block.call(StringIO.new(contents))
      }) do
        with_stubbed_method(Getch::Log, :new, -> { @log }) do
          tarball = Getch::Gentoo::Tarball.new

          assert_equal "#{filename}-20251128T120000Z.tar.xz", tarball.instance_variable_get(:@stage_file)
          assert_equal '20251128T120000Z/stage3-amd64-' \
                       "#{variant}-20251128T120000Z.tar.xz", tarball.send(:file)
        end
      end
    end
  end

  def test_release_returns_first_matching_timestamp
    tarball = build_tarball
    contents = "not a release\n" \
               "20251128T120000Z/stage3-amd64-systemd-20251128T120000Z.tar.xz 123\n" \
               "20251129T120000Z/stage3-amd64-systemd-20251129T120000Z.tar.xz 456\n"
    requested_url = nil

    with_stubbed_method(URI, :open, lambda { |url, &block|
      requested_url = url
      block.call(StringIO.new(contents))
    }) do
      assert_equal '20251128T120000Z', tarball.send(:release)
    end

    assert_equal "#{tarball.instance_variable_get(:@mirror)}/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt",
                 requested_url
  end

  def test_get_stage3_downloads_only_when_archive_is_missing
    Dir.mktmpdir do |mountpoint|
      original_directory = Dir.pwd
      Getch::OPTIONS[:mountpoint] = mountpoint
      tarball = build_tarball
      url = 'https://mirror.rackspace.com/gentoo/releases/amd64/autobuilds/20251128T120000Z/stage3-amd64-systemd-20251128T120000Z.tar.xz'
      downloads = []

      begin
        with_stubbed_method(Getch::Helpers, :get_file_online, lambda { |source, destination|
          downloads << [source, destination]
          File.write(destination, 'archive')
        }) do
          tarball.send(:get_stage3)
          tarball.send(:get_stage3)
        end
      ensure
        Dir.chdir(original_directory)
      end

      assert_equal [[url, 'stage3-amd64-systemd-20251128T120000Z.tar.xz']], downloads
    end
  end

  def test_control_files_downloads_all_sidecars
    tarball = build_tarball
    downloads = []

    with_stubbed_method(Getch::Helpers, :get_file_online, lambda { |url, destination|
      downloads << [url, destination]
    }) do
      tarball.send(:control_files)
    end

    file = '20251128T120000Z/stage3-amd64-systemd-20251128T120000Z.tar.xz'
    base_url = "https://mirror.rackspace.com/gentoo/releases/amd64/autobuilds/#{file}"
    assert_equal %w[DIGESTS asc CONTENTS.gz].map { |ext| ["#{base_url}.#{ext}", "#{File.basename(file)}.#{ext}"] },
                 downloads
    assert_equal %i[info result_ok], @log.events
  end

  def test_checksum_reports_success_and_cleans_up_on_failure
    tarball = build_tarball
    status = command_status(true)
    command = nil

    with_stubbed_method(Open3, :capture3, lambda { |value|
      command = value
      ['', '', status]
    }) do
      tarball.send(:checksum)
    end

    assert_equal "awk '/SHA512 HASH/{getline;print}' #{@stage_file}.DIGESTS | sha512sum --check", command
    assert_equal [:info, :result_ok], @log.events

    cleaned = false
    failed_status = command_status(false)
    with_stubbed_method(tarball, :cleaning, -> { cleaned = true }) do
      with_stubbed_method(Open3, :capture3, ->(_value) { ['', 'bad checksum', failed_status] }) do
        tarball.send(:checksum)
      end
    end

    assert cleaned
    assert_equal [:info, :result_ok, :info, :fatal], @log.events
    assert_match(/bad checksum/, @log.fatal_message)
  end

  def test_x_runs_download_verification_and_install_steps_in_order
    tarball = build_tarball
    events = []
    with_stubbed_method(tarball, :get_stage3, -> { events << :download }) do
      with_stubbed_method(tarball, :control_files, -> { events << :sidecars }) do
        with_stubbed_method(tarball, :checksum, -> { events << :checksum }) do
          with_stubbed_method(tarball, :install, -> { events << :install }) do
            tarball.x
          end
        end
      end
    end

    assert_equal %i[download sidecars checksum install], events
  end

  private

  def build_tarball
    Getch::Gentoo::Tarball.allocate.tap do |tarball|
      tarball.instance_variable_set(:@log, @log)
      tarball.instance_variable_set(:@mirror, 'https://mirror.rackspace.com/gentoo')
      tarball.instance_variable_set(:@release, '20251128T120000Z')
      @stage_file = 'stage3-amd64-systemd-20251128T120000Z.tar.xz'
      tarball.instance_variable_set(:@stage_file, @stage_file)
    end
  end

  def command_status(success)
    Object.new.tap { |status| status.define_singleton_method(:success?) { success } }
  end

  def with_stubbed_method(object, name, replacement)
    stub = Module.new { define_method(name, replacement) }
    object.singleton_class.prepend(stub)
    yield
  ensure
    stub&.remove_method(name)
  end

  class FakeLog
    attr_reader :events, :fatal_message

    def initialize
      @events = []
    end

    def info(_message)
      @events << :info
    end

    def result_ok
      @events << :result_ok
    end

    def fatal(message)
      @events << :fatal
      @fatal_message = message
    end
  end
end

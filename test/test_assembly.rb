# frozen_string_literal: true

require 'minitest/autorun'
require 'getch'

class AssemblyTest < Minitest::Test
  def setup
    @original_states = Getch::STATES.dup
    @original_options = Getch::OPTIONS.dup
    Getch::STATES.clear
    @events = []
    events = @events

    @fs = Module.new
    @os = Module.new
    {
      @fs => { Partition: :partition, Format: :format, Mount: :mount,
               Deps: :fs_deps, Config: :fs_config },
      @os => { PreConfig: :pre_config, Update: :update, PostConfig: :post_config,
               Terraform: :os_terraform, Services: :services, Finalize: :finalize }
    }.each do |container, classes|
      classes.each do |name, event|
        container.const_set(name, Class.new do
          define_method(:initialize) { events << event }
        end)
      end
    end
    @os.const_set(:Tarball, Class.new do
      define_method(:x) { events << :tarball }
    end)
    @os.const_set(:Bootloader, Class.new do
      define_method(:dependencies) { events << :bootloader_deps }
      define_method(:install) { events << :bootloader_install }
    end)
    @fs.define_singleton_method(:end) { events << :fs_end }

    state = Object.new
    %i[partition format mount tarball pre_config update post_config terraform
       services luks_keys bootloader finalize].each do |step|
      state.define_singleton_method(step) do
        events << :"saved_#{step}"
        Getch::STATES[step] = true
      end
    end
    @assembly = Getch::Assembly.allocate
    @assembly.instance_variable_set(:@fs, @fs)
    @assembly.instance_variable_set(:@os, @os)
    @assembly.instance_variable_set(:@state, state)
  end

  def teardown
    Getch::STATES.replace(@original_states)
    Getch::OPTIONS.replace(@original_options)
  end

  def test_steps_run_in_order_and_are_skipped_after_completion
    with_stubbed_method(Getch::Helpers, :mount_all, -> { @events << :mount_all }) do
      %i[partition format mount tarball pre_config update post_config terraform
         services bootloader finalize].each do |step|
        capture_io { @assembly.public_send(step) }
        before = @events.dup
        capture_io { @assembly.public_send(step) }
        assert_equal before, @events, "#{step} should not run twice"
      end
    end

    assert_equal %i[
      partition saved_partition format saved_format mount saved_mount
      tarball saved_tarball pre_config saved_pre_config mount_all update saved_update
      post_config saved_post_config os_terraform fs_deps saved_terraform
      services saved_services bootloader_deps fs_config bootloader_install
      saved_bootloader finalize fs_end saved_finalize
    ], @events
  end

  def test_failed_step_is_not_marked_complete
    @fs.send(:remove_const, :Format)
    @fs.const_set(:Format, Class.new do
      def initialize
        raise 'format failed'
      end
    end)

    assert_raises(RuntimeError) { @assembly.format }
    refute Getch::STATES[:format]
    assert_empty @events
  end

  def test_luks_keys_only_runs_for_non_zfs_encryption
    crypt = Object.new
    events = @events
    crypt.define_singleton_method(:keys) { events << :keys }
    with_stubbed_method(CryptSetup, :new, ->(*_args) { crypt }) do
      Getch::OPTIONS[:encrypt] = false
      Getch::OPTIONS[:fs] = 'ext4'
      @assembly.luks_keys
      Getch::OPTIONS[:encrypt] = true
      Getch::OPTIONS[:fs] = 'zfs'
      @assembly.luks_keys
      assert_empty @events

      Getch::OPTIONS[:fs] = 'ext4'
      @assembly.luks_keys
      @assembly.luks_keys
      assert_equal %i[keys saved_luks_keys], @events
    end

    private

    def with_stubbed_method(object, name, replacement)
      original = object.method(name)
      object.define_singleton_method(name, replacement)
      yield
    ensure
      object.define_singleton_method(name, original)
    end
  end
end

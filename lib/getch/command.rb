# frozen_string_literal: true

require 'open3'
require 'nito'

module Getch
  class Command
    def initialize(*args)
      @cmd = args.join(' ')
      @block_size = 1024
      @log = Getch::Log.new
    end

    def run!
      tab = add_tab
      @log.info 'Exec: ' + @cmd + " #{@cmd.length}" + tab

      Open3.popen3(@cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write
        code = wait_thr.value

        unless code.success?
          begin
            @log.debug stderr.readline until stderr.eof.nil?
          rescue EOFError => e
            print
          end
        end

        begin
          files = [stdout, stderr]

          until all_eof(files) do
            ready = IO.select(files)
            ready && display_lines(ready[0])
          end
        rescue IOError => e
          @log.error e
        end

        if code.success?
          @log.result 'Ok'
          return stdout.read
        end

        puts
        @log.error "#{@cmd} - #{code}"
        @log.fatal "Running #{@cmd}"
      end
    end

    private

    def add_tab
      case @cmd.length
      when 27..32 then "\t\t"
      when 16..23 then "\t\t\t"
      else "\t"
      end
    end

    # Returns true if all files are EOF
    def all_eof(files)
      files.find { |f| !f.eof }.nil?
    end

    def display_lines(block)
      block.each do |f|
        begin
          data = f.read_nonblock(@block_size)
          puts data if OPTIONS[:verbose]
        rescue EOFError
          print
        rescue => e
          @log.fatal e
        end
      end
    end
  end

  # Use system, the only ruby method to display stdout with colors !
  class Emerge
    def initialize(cmd)
      @gentoo = MOUNTPOINT
      @cmd = cmd
      @log = Getch::Log.new
    end

    def run!
      @log.info "Running emerge: #{@cmd}"
      system('chroot', @gentoo, '/bin/bash', '-c', "source /etc/profile && #{@cmd}")
      read_exit
    end

    def pkg!
      @log.info "Running emerge pkg: #{@cmd}"
      system('chroot', @gentoo, '/bin/bash', '-c', "source /etc/profile && emerge --changed-use #{@cmd}")
      read_exit
    end

    private

    def read_exit
      if $?.exitstatus > 0
        @log.fatal "Running #{@cmd}"
      else
        @log.info "Done #{@cmd}"
      end
    end
  end

  class Make
    def initialize(cmd)
      @gentoo = MOUNTPOINT
      @cmd = cmd
      @log = Getch::Log.new
    end

    def run!
      @log.info "Running Make: #{@cmd}"
      cmd = "chroot #{@gentoo} /bin/bash -c \"source /etc/profile \
        && env-update \
        && cd /usr/src/linux \
        && #{@cmd}\""
      Open3.popen2e(cmd) do |_, stdout_err, wait_thr|
        stdout_err.each { |l| puts l }

        exit_status = wait_thr.value
        unless exit_status.success?
          @log.fatal "Running #{cmd}"
          exit 1
        end
      end
    end
  end

  class Bask
    include NiTo

    def initialize(cmd)
      @cmd = cmd
      @log = Getch::Log.new
      @version = '0.6'
      @config = "#{MOUNTPOINT}/etc/kernel/config.d"
      download_bask unless Dir.exist? "#{MOUNTPOINT}/root/bask-#{@version}"
    end

    def run!
      @log.info "Running Bask: #{@cmd}"
      cmd = "chroot #{MOUNTPOINT} /bin/bash -c \"source /etc/profile \
        && env-update \
        && cd /root/bask-#{@version} \
        && ./bask.sh #{@cmd} -k /usr/src/linux\""
      Open3.popen2e(cmd) do |_, stdout_err, wait_thr|
        stdout_err.each { |l| puts l }

        exit_status = wait_thr.value
        unless exit_status.success?
          @log.fatal "Running #{cmd}"
          exit 1
        end
      end
    end

    def cp
      mkdir @config
      Helpers.cp(
        "#{MOUNTPOINT}/root/bask-#{@version}/config.d/#{@cmd}",
        "#{@config}/#{@cmd}"
      )
    end

    def add(content)
      Helpers.add_file "#{@config}/#{@cmd}", content
    end

    private

    def download_bask
      @log.info 'Installing Bask...'
      url = "https://github.com/szorfein/bask/archive/refs/tags/#{@version}.tar.gz"
      file = "bask-#{@version}.tar.gz"

      Dir.chdir("#{MOUNTPOINT}/root")
      Helpers.get_file_online(url, file)
      Getch::Command.new("tar xzf #{file}").run!
    end
  end

  class Chroot < Command
    def initialize(cmd)
      super
      @cmd = "chroot #{MOUNTPOINT} /bin/bash -c \"source /etc/profile; #{cmd}\""
    end
  end
end

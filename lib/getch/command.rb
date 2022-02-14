# frozen_string_literal: true

require 'open3'
require 'nito'

module Getch
  class Command
    attr_reader :res

    def initialize(*args)
      @cmd = args.join(' ')
      @block_size = 1024
      @log = Getch::Log.new
      x
    end

    def to_s
      @res
    end

    protected

    def x
      @log.info 'Exec: ' + @cmd
      cmd = build_cmd

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write
        code = wait_thr.value

        unless code.success?
          begin
            @log.debug stderr.readline until stderr.eof.nil?
          rescue EOFError
            print
          end
        end

        if code.success?
          @log.result_ok
          @res = stdout.read.chomp
          return
        end

        puts
        @log.error "#{@cmd} - #{code}"
        @log.fatal "Running #{@cmd}"
      end
    end

    private

    def build_cmd
      @cmd
    end
  end

  # Use system, the only ruby method to display stdout with colors !
  class Emerge
    def initialize(cmd)
      @gentoo = MOUNTPOINT
      @cmd = cmd
      @log = Getch::Log.new
    end

    def pkg!
      @log.info "Running emerge pkg: #{@cmd}\n"
      system('chroot', @gentoo, '/bin/bash', '-c', "source /etc/profile && emerge --changed-use #{@cmd}")
      read_exit
    end

    private

    def read_exit
      if $?.exitstatus > 0
        @log.fatal "Running #{@cmd}"
      else
        @log.info "Done #{@cmd}\n"
      end
    end
  end

  class Bask
    def initialize(cmd)
      @cmd = cmd
      @log = Log.new
      @version = '0.6'
      @config = "#{MOUNTPOINT}/etc/kernel/config.d"
      download_bask unless Dir.exist? "#{MOUNTPOINT}/root/bask-#{@version}"
    end

    def cp
      NiTo.mkdir @config
      NiTo.cp(
        "#{MOUNTPOINT}/root/bask-#{@version}/config.d/#{@cmd}",
        "#{@config}/#{@cmd}"
      )
    end

    def add(content)
      Helpers.add_file "#{@config}/#{@cmd}", content
    end

    private

    def download_bask
      @log.info "Installing Bask...\n"
      url = "https://github.com/szorfein/bask/archive/refs/tags/#{@version}.tar.gz"
      file = "bask-#{@version}.tar.gz"

      Dir.chdir("#{MOUNTPOINT}/root")
      Helpers.get_file_online(url, file)
      Getch::Command.new("tar xzf #{file}")
    end
  end

  class Chroot < Command
    def build_cmd
      dest = OPTIONS[:mountpoint]
      case OPTIONS[:os]
      when 'gentoo'
        "chroot #{dest} /bin/bash -c \"source /etc/profile; #{@cmd}\""
      when 'void'
        "chroot #{dest} /bin/bash -c \"#{@cmd}\""
      end
    end
  end

  class ChrootOutput
    def initialize(*args)
      @cmd = args.join(' ')
      @log = Log.new
      x
    end

    private

    def x
      msg
      system('chroot', OPTIONS[:mountpoint], '/bin/bash', '-c', other_args)
      $?.success? && return

      @log.fatal "Running #{@cmd}"
    end

    def msg
      @log.info "Exec: #{@cmd}...\n"
    end

    def other_args
      case OPTIONS[:os]
      when 'gentoo' then "source /etc/profile && #{@cmd}"
      when 'void' then @cmd
      end
    end
  end

  # Install
  # use system() to install packages
  # Usage: Install.new(pkg_name)
  class Install < ChrootOutput
    def msg
      @log.info "Installing #{@cmd}...\n"
    end

    def other_args
      case OPTIONS[:os]
      when 'gentoo' then "source /etc/profile && emerge --changed-use #{@cmd}"
      when 'void' then "/usr/bin/xbps-install -y #{@cmd}"
      end
    end
  end
end

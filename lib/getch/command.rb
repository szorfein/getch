require 'open3'

module Getch
  class Command
    def initialize(cmd)
      @cmd = cmd
      @block_size = 1024
      @log = Getch::Log.new
    end

    def run!
      @log.info "Running command: " + @cmd.gsub(/\"/, '')

      Open3.popen3(@cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write
        code = wait_thr.value

        # only stderr
        begin
          @log.debug stderr.readline until stderr.eof.nil?
        rescue EOFError
        end

        begin
          files = [stdout, stderr]

          until all_eof(files) do
            ready = IO.select(files)

            if ready
              readable = ready[0]
              # writable = ready[1]
              # exceptions = ready[2]

              display_lines(readable)
            end
          end
        rescue IOError => e
          puts "IOError: #{e}"
        end

        unless code.success?
          @log.fatal "Running #{@cmd}"
          exit 1
        end

        @log.debug "Done - #{@cmd} - #{code}"
      end
    end

    private

    # Returns true if all files are EOF
    def all_eof(files)
      files.find { |f| !f.eof }.nil?
    end

    def display_lines(block)
      block.each do |f|
        begin
          data = f.read_nonblock(@block_size)
          puts data if DEFAULT_OPTIONS[:verbose]
        rescue EOFError
          puts ""
        rescue => e
          puts "Fatal - #{e}"
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
      system("chroot", @gentoo, "/bin/bash", "-c", "source /etc/profile && #{@cmd}")
      read_exit
    end

    def pkg!
      @log.info "Running emerge pkg: #{@cmd}"
      system("chroot", @gentoo, "/bin/bash", "-c", "source /etc/profile && emerge --changed-use #{@cmd}")
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
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          puts line
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          @log.fatal "Running #{cmd}"
          exit 1
        end
      end
    end
  end

  class Bask
    def initialize(cmd)
      @gentoo = MOUNTPOINT
      @cmd = cmd
      @log = Getch::Log.new
      @version = "0.3"
    end

    def run!
      download_bask if ! Dir.exist? "#{MOUNTPOINT}/root/bask-#{@version}"
      @log.info "Running Bask: #{@cmd}"
      cmd = "chroot #{@gentoo} /bin/bash -c \"source /etc/profile \
        && env-update \
        && cd /root/bask-#{@version} \
        && ./bask.sh #{@cmd} -k /usr/src/linux\""
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          puts line
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          @log.fatal "Running #{cmd}"
          exit 1
        end
      end
    end

    private 

    def download_bask
      @log.info "Installing Bask..."
      url = "https://github.com/szorfein/bask/archive/v#{@version}.tar.gz"
      file = "bask-#{@version}.tar.gz"

      Dir.chdir("#{MOUNTPOINT}/root")
      Helpers::get_file_online(url, file)
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

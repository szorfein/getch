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
          @logger.error stderr.readline until stderr.eof.nil?
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
        @logger.debug "Done - #{@cmd} - #{code}"
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
          puts "#{data}" if DEFAULT_OPTIONS[:verbose]
        rescue EOFError
          puts ""
        rescue => e
          puts "Fatal - #{e}"
        end
      end
    end
  end
end

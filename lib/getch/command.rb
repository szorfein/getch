require 'open3'

module Getch
  class Command
    def initialize(cmd)
      @cmd = cmd
      @block_size = 512
    end

    def run!
      puts "Running command: " + @cmd.gsub(/\"/, '')

      Open3.popen3(@cmd) do |stdin, stdout, stderr|
        stdin.close_write

        begin
          files = [stdout, stderr]

          until all_eof(files) do
            ready = IO.select(files)

            if ready
              readable = ready[0]
              # writable = ready[1]
              # exceptions = ready[2]

              readable.each do |f|
                fileno = f.fileno

                begin
                  data = f.read_nonblock(@block_size)

                  # Do something with the data...
                  puts "#{data}" if DEFAULT_OPTIONS[:verbose]
                rescue EOFError
                  puts "fileno: #{fileno} EOF"
                end
              end
            end
          end
        rescue IOError => e
          puts "IOError: #{e}"
        end
      end
      puts "Done"
    end

    private

    # Returns true if all files are EOF
    def all_eof(files)
      files.find { |f| !f.eof }.nil?
    end
  end
end

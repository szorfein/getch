require 'open-uri'
require 'open3'

module Getch
  module Void
    class Xbps
      def initialize
        @url = "https://alpha.de.repo.voidlinux.org/static"
        @file = "sha256sums.txt"
        @xbps = false
        Dir.chdir(MOUNTPOINT)
      end

      def search_archive
        URI.open("#{@url}/#{@file}") do |file|
          # Read the bottom/end
          IO.readlines(file)[-10..-1].each { |l|
            @xbps = l.split(" ") if l.match(/(^[[:alnum:]]+\s+)xbps-static-static-[\d._]+.x86_64-musl.tar.xz/)
          }
        end
      end

      def download
        raise StandardError, "No file found, retry later." if !@xbps
        return if File.exist? @xbps[1]
        puts "Downloading #{@xbps[1]}..." # => xbps-static-static-X.XX_X.x86_64-musl.tar.xz
        Helpers::get_file_online("#{@url}/#{@xbps[1]}", @xbps[1])
      end

      def checksum
        print ' => Checking SHA256 checksum...'
        # Should contain 2 spaces...
        command = "echo #{@xbps[0]}  #{@xbps[1]} | sha256sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success? then
          puts "\t[OK]"
          decompress
          cleaning
          return
        end
        cleaning
        raise "Problem with the checksum, stderr\n#{stderr}"
      end

      private

      def decompress
        print " => Decompressing archive #{@xbps[1]}..."
        cmd = "tar xpf #{@xbps[1]} --xattrs-include=\'*.*\' --numeric-owner"
        _, stderr, status = Open3.capture3(cmd)
        if status.success? then
          puts "\s[OK]"
          return
        end
        cleaning
        raise "Fail to decompress archive #{@xbps[1]} - #{stderr}."
      end

      def cleaning
        Dir.glob("xbps-static-static-*.tar.xz").each do |f|
          File.delete(f)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'open-uri'
require 'open3'

module Getch
  module Void
    class Tarball
      def initialize
        @url = 'https://alpha.de.repo.voidlinux.org/live/current'
        @file = 'sha256sum.txt'
        @xbps = false
        Dir.chdir OPTIONS[:mountpoint]
      end

      def x
        search_archive
        download
        checksum
        install
      end

      protected

      def tarball
        OPTIONS[:musl] ?
          /void-x86_64-musl-ROOTFS-[\d._]+.tar.xz/ :
          /void-x86_64-ROOTFS-[\d._]+.tar.xz/
      end

      # Search only the glibc x86_64 for now
      def search_archive
        yurl = "#{@url}/#{@file}"
        puts "Open #{yurl}"
        Helpers.get_file_online(yurl, @file)
        File.open(@file).each do |l|
          @xbps = l.tr('()', '').split(' ') if l.match(tarball)
        end
      end

      def download
        raise StandardError, 'No file found, retry later.' unless @xbps
        return if File.exist? @xbps[1]

        puts "Downloading #{@xbps[1]}..."
        Helpers.get_file_online("#{@url}/#{@xbps[1]}", @xbps[1])
      end

      def checksum
        print ' => Checking SHA256 checksum...'
        # Should contain 2 spaces...
        command = "echo #{@xbps[3]}  #{@xbps[1]} | sha256sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success? then
          puts "\t[OK]"
          return
        end
        cleaning
        abort "Problem with the checksum, stderr\n#{stderr}"
      end

      def install
        decompress
        cleaning
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
        Dir.glob('void-x86_64*.tar.xz').each { |f| File.delete(f) }
        Dir.glob('sha256*').each { |f| File.delete(f) }
      end
    end
  end
end

# frozen_string_literal: true

require 'open-uri'
require 'open3'

module Getch
  module Void
    class Tarball
      def initialize
        @log = Log.new
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
        @log.info "Opening #{yurl}...\n"
        Helpers.get_file_online(yurl, @file)
        File.open(@file).each do |l|
          @xbps = l.tr('()', '').split(' ') if l.match(tarball)
        end
      end

      def download
        @log.fatal 'No file found, retry later.' unless @xbps
        return if File.exist? @xbps[1]

        @log.info "Downloading #{@xbps[1]}..."
        Helpers.get_file_online("#{@url}/#{@xbps[1]}", @xbps[1])
        @log.result_ok
      end

      def checksum
        @log.info 'Checking SHA256 checksum...'
        # Should contain 2 spaces...
        command = "echo #{@xbps[3]}  #{@xbps[1]} | sha256sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success? then
          @log.result_ok
          return
        end
        cleaning
        @log.fatal "Problem with the checksum, stderr\n#{stderr}"
      end

      def install
        decompress
        cleaning
      end

      private

      def decompress
        @log.info "Decompressing #{@xbps[1]}..."
        cmd = "tar xpf #{@xbps[1]} --xattrs-include=\'*.*\' --numeric-owner"
        _, stderr, status = Open3.capture3(cmd)
        if status.success? then
          @log.result_ok
          return
        end
        cleaning
        @log.fatal "Fail to decompressing #{@xbps[1]} - #{stderr}."
      end

      def cleaning
        Dir.glob('void-x86_64*.tar.xz').each { |f| File.delete(f) }
        Dir.glob('sha256*').each { |f| File.delete(f) }
      end
    end
  end
end

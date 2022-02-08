# frozen_string_literal: true

require 'open-uri'
require 'open3'

module Getch
  module Gentoo
    class Tarball
      def initialize
        @log = Log.new
        @mirror = 'https://mirror.rackspace.com/gentoo'
        @release = release
        @stage_file = OPTIONS[:musl] ?
          "stage3-amd64-musl-#{@release}.tar.xz" :
          "stage3-amd64-systemd-#{@release}.tar.xz"
      end

      def x
        get_stage3
        control_files
        checksum
        install
      end

      protected

      def stage3
        OPTIONS[:musl] ?
          @mirror + '/releases/amd64/autobuilds/latest-stage3-amd64-musl.txt' :
          @mirror + '/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt'
      end

      def release
        URI.open(stage3) do |file|
          file.read.match(/^[[:alnum:]]+/)
        end
      rescue Net::OpenTimeout => e
        @log.fatal "Problem with DNS? #{e}"
      end

      def file
        "#{@release}/#{@stage_file}"
      end

      def get_stage3
        Dir.chdir OPTIONS[:mountpoint]
        return if File.exist? @stage_file

        @log.info "wget #{@stage_file}, please wait...\n"
        Helpers.get_file_online(@mirror + '/releases/amd64/autobuilds/' + file, @stage_file)
      end

      def control_files
        @log.info "Download other files..."
        ['DIGESTS', 'DIGESTS.asc', 'CONTENTS.gz'].each do |f|
          Helpers.get_file_online("#{@mirror}/releases/amd64/autobuilds/#{file}.#{f}", "#{@stage_file}.#{f}")
        end
        @log.result_ok
      end

      def checksum
        @log.info 'Checking SHA512 checksum...'
        command = "awk '/SHA512 HASH/{getline;print}' #{@stage_file}.DIGESTS.asc | sha512sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success? then
          @log.result_ok
        else
          cleaning
          @log.fatal "Problem with the checksum, stderr\n#{stderr}"
        end
      end

      def install
        decompress
        cleaning
      end

      private

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage
      def decompress
        cmd = "tar xpf #{@stage_file} --xattrs-include=\'*.*\' --numeric-owner"
        Getch::Command.new(cmd)
      end

      def cleaning
        Dir.glob('stage3-amd64-*').each { |f| File.delete(f) }
      end
    end
  end
end

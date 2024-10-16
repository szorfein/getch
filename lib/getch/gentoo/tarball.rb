# frozen_string_literal: true

require 'open-uri'
require 'open3'

module Getch
  module Gentoo
    # Download the last archive rootfs
    class Tarball
      def initialize
        @log = Log.new
        @mirror = 'https://mirror.rackspace.com/gentoo'
        @release = release
        @stage_file = if OPTIONS[:musl]
                        "stage3-amd64-musl-#{@release}.tar.xz"
                      else
                        "stage3-amd64-systemd-#{@release}.tar.xz"
                      end
      end

      def x
        get_stage3
        control_files
        checksum
        install
      end

      protected

      def stage3
        if OPTIONS[:musl]
          "#{@mirror}/releases/amd64/autobuilds/latest-stage3-amd64-musl.txt"
        else
          "#{@mirror}/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt"
        end
      end

      # release check line like bellow and return 20231126T163200Z:
      # 20231126T163200Z/stage3-amd64-systemd-20231126T163200Z.tar.xz 276223256
      def release
        URI.open(stage3) do |file|
          file.each do |line|
            return line.split('/')[0] if line.match(%r{^[\w]+[/](.*)tar.xz})
          end
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
        Helpers.get_file_online("#{@mirror}/releases/amd64/autobuilds/#{file}", @stage_file)
      end

      def control_files
        @log.info 'Download other files...'
        ['DIGESTS', 'asc', 'CONTENTS.gz'].each do |f|
          Helpers.get_file_online("#{@mirror}/releases/amd64/autobuilds/#{file}.#{f}", "#{@stage_file}.#{f}")
        end
        @log.result_ok
      end

      def checksum
        @log.info 'Checking SHA512 checksum...'
        command = "awk '/SHA512 HASH/{getline;print}' #{@stage_file}.DIGESTS | sha512sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success?
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

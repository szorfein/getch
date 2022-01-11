require 'open-uri'
require 'open3'

module Getch
  module Gentoo
    class Stage
      def initialize
        @mirror = 'https://mirrors.soeasyto.com/distfiles.gentoo.org'
        @release = release
        @stage_file="stage3-amd64-systemd-#{@release}.tar.xz"
      end

      def stage3
        @mirror + '/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt'
      end

      def release
        URI.open(stage3) do |file|
          file.read.match(/^[[:alnum:]]+/)
        end
      end

      def file
        "#{@release}/#{@stage_file}"
      end

      def get_stage3
        Dir.chdir(MOUNTPOINT)
        return if File.exist?(@stage_file)
        puts "Download the last #{@stage_file}, please wait..."
        Helpers.get_file_online(@mirror + '/releases/amd64/autobuilds/' + file, @stage_file)
      end

      def control_files
        puts 'Download the DIGESTS'
        Helpers.get_file_online(@mirror + '/releases/amd64/autobuilds/' + file + '.DIGESTS', "#{@stage_file}.DIGESTS")
        puts 'Download the DIGESTS.asc'
        Helpers.get_file_online(@mirror + '/releases/amd64/autobuilds/' + file + '.DIGESTS.asc', "#{@stage_file}.DIGESTS.asc")
        puts "Download the CONTENTS.gz"
        Helpers.get_file_online(@mirror + '/releases/amd64/autobuilds/' + file + '.CONTENTS.gz', "#{@stage_file}.CONTENTS.gz")
      end

      def checksum
        puts 'Check the SHA512 checksum.'
        command = "awk '/SHA512 HASH/{getline;print}' #{@stage_file}.DIGESTS.asc | sha512sum --check"
        _, stderr, status = Open3.capture3(command)
        if status.success? then
          puts 'Checksum is ok'
          decompress
          cleaning
        else
          cleaning
          raise "Problem with the checksum, stderr\n#{stderr}"
        end
      end

      private

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage
      def decompress
        puts "Decompressing archive #{@stage_file}..."
        cmd = "tar xpf #{@stage_file} --xattrs-include=\'*.*\' --numeric-owner"
        Getch::Command.new(cmd).run!
      end

      def cleaning
        Dir.glob('stage3-amd64-systemd*').each { |f| File.delete(f) }
      end
    end
  end
end

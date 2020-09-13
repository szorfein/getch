require 'fileutils'

module Getch
  module Gentoo
    class Config
      def initialize
        @make = "#{MOUNTPOINT}/etc/portage/make.conf"
      end

      def portage
        nproc = `nproc`.chomp()
        data = [
          '',
          'ACCEPT_KEYWORD="amd64 ~amd64"',
          "MAKEOPTS=\"-j#{nproc} -l#{nproc}\"",
          'INPUT_DEVICES="libinput synaptics"'
        ]
        File.write(@make, data.join("\n"), mode:"a")
      end

      def repo
        src = "#{MOUNTPOINT}/usr/share/portage/config/repos.conf"
        dest = "#{MOUNTPOINT}/etc/portage/repos.conf"
        FileUtils.mkdir dest, mode: 0644 if ! Dir.exist?(dest)
        FileUtils.copy_file(src, "#{dest}/gentoo.conf", preserve = false)
      end

      def network
        src = '/etc/resolv.conf'
        dest = "#{MOUNTPOINT}/etc/resolv.conf"
        FileUtils.copy_file(src, dest, preserve = false)
      end

      def systemd(options)
        File.write("#{MOUNTPOINT}/etc/locale.gen", "#{options.language}.UTF-8 UTF-8")
        File.write("#{MOUNTPOINT}/etc/locale.conf", "#{options.language}.UTF-8")
        File.write("#{MOUNTPOINT}/etc/vconsole.conf", "KEYMAP=\"#{options.keyboard}\"")
      end
    end
  end
end

require 'fileutils'
require 'tempfile'

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
        File.write(@make, data.join("\n"), mode: "a")
      end

      def repo
        src = "#{MOUNTPOINT}/usr/share/portage/config/repos.conf"
        dest = "#{MOUNTPOINT}/etc/portage/repos.conf"
        FileUtils.mkdir dest, mode: 0644 if ! Dir.exist?(dest)
        line_count = 0
        tmp_file = Tempfile.new('gentoo.conf')
        File.open(src).each { |l|
          File.write(tmp_file, "sync-allow-hardlinks = yes\n", mode: 'a') if line_count == 2
          File.write(tmp_file, l, mode: 'a')
          line_count += 1
        }
        FileUtils.copy_file(tmp_file, "#{dest}/gentoo.conf", preserve = false)
      end

      def network
        src = '/etc/resolv.conf'
        dest = "#{MOUNTPOINT}/etc/resolv.conf"
        FileUtils.copy_file(src, dest, preserve = false)
      end

      def systemd(options)
        control_options(options)
        File.write("#{MOUNTPOINT}/etc/locale.gen", @utf8)
        File.write("#{MOUNTPOINT}/etc/locale.conf", "LANG=#{@lang}")
        File.write("#{MOUNTPOINT}/etc/locale.conf", 'LC_COLLATE=C', mode: 'a')
        File.write("#{MOUNTPOINT}/etc/timezone", "#{options.zoneinfo}")
        File.write("#{MOUNTPOINT}/etc/vconsole.conf", "KEYMAP=#{@keymap}")
      end

      private

      def control_options(options)
        search_zone(options.zoneinfo)
        search_utf8(options.language)
        search_key(options.keyboard)
      end

      def search_key(keys)
        @keymap = nil
        Dir.glob("#{MOUNTPOINT}/usr/share/keymaps/**/#{keys}.map.gz") { |f|
          @keymap = f
        }
        raise "No keymap #{@keymap} found" if ! @keymap
      end

      def search_zone(zone)
        if ! File.exist?("#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}")
          raise "Zoneinfo #{zone} doesn\'t exist."
        end
      end

      def search_utf8(lang)
        @utf8, @lang = nil, nil
        File.open("#{MOUNTPOINT}/usr/share/i18n/SUPPORTED").each { |l|
          @utf8 = $~[0] if l.match(/^#{lang}[. ]+[utf\-8 ]+/i)
          @lang = $~[0] if l.match(/^#{lang}[. ]+utf\-8/i)
        }
        raise "Lang #{lang} no found" if ! @utf8
      end
    end
  end
end

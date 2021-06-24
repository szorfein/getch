require 'fileutils'
require 'securerandom'

module Getch
  module Void
    class Config
      def initialize
        @log = Getch::Log.new
        @network_dir = "#{MOUNTPOINT}/etc"
        @id = SecureRandom.hex(2)
      end

      def network
        print " => Copying /etc/resolv.conf..."
        FileUtils.mkdir_p @network_dir unless Dir.exist? @network_dir
        src = '/etc/resolv.conf'
        dest = "#{@network_dir}/resolv.conf"
        FileUtils.copy_file(src, dest, preserve = true)
        puts "\s[Ok]"
      end

      def system
        print " => Updating configs system..."
        control_options
        rc = "#{MOUNTPOINT}/etc/rc.conf"
        add_line(rc, "HARDWARECLOCK=\"UTC\"") if !search(rc, /^HARDWARECLOCK/)
        add_line(rc, "KEYMAP=\"#{Getch::OPTIONS[:keymap]}\"") if !search(rc, /^KEYMAP/)
        add_line(rc, "TIMEZONE=\"#{Getch::OPTIONS[:zoneinfo]}\"") if !search(rc, /^TIMEZONE/)
        add_line(rc, "HOSTNAME=\"void-hatch-#{@id}\"") if !search(rc, /^HOSTNAME/)
        puts "\s[OK]"
      end

      def locale
        print " => Updating locale system..."
        conf = "#{MOUNTPOINT}/etc/locale.conf"
        File.write(conf, "LANG=#{@lang}\n")
        add_line(conf, "LC_COLLATE=C")
      end

      def fstab
        print " => Configuring fstab..."
        conf = "#{MOUNTPOINT}/etc/fstab"
        add_line(conf, "tmpfs /tmp tmpfs defaults,nosuid,nodev 0 0") if !search(conf, /^tmpfs/)
        puts "\s[OK]"
      end

      private

      def add_line(file, line)
        raise "No file #{file} found !" unless File.exist? file
        File.write(file, "#{line}\n", mode: 'a')
      end

      def search(file, text)
        File.open(file).each { |line|
          return true if line.match(/#{text}/)
        }
        return false
      end

      def control_options
        search_zone(Getch::OPTIONS[:zoneinfo])
        search_utf8(Getch::OPTIONS[:language])
        search_key(Getch::OPTIONS[:keymap])
      end

      def search_key(keys)
        @keymap = nil
        Dir.glob("#{MOUNTPOINT}/usr/share/keymaps/**/#{keys}.map.gz") { |f|
          @keymap = f
        }
        raise ArgumentError, "No keymap #{@keymap} found" if ! @keymap
      end

      def search_zone(zone)
        if !File.exist?("#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}")
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end

      def search_utf8(lang)
        @utf8, @lang = nil, nil
        File.open("#{MOUNTPOINT}/usr/share/i18n/SUPPORTED").each { |l|
          @utf8 = $~[0] if l.match(/^#{lang}[. ]+[utf\-8 ]+/i)
          @lang = $~[0] if l.match(/^#{lang}[. ]+utf\-8/i)
        }
        raise ArgumentError, "Lang #{lang} no found" if ! @utf8
      end
    end
  end
end

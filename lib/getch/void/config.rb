# frozen_string_literal: true

require 'fileutils'
require 'securerandom'

module Getch
  module Void
    class Config
      include Helpers::Void

      def initialize
        @log = Getch::Log.new
        @network_dir = "#{MOUNTPOINT}/etc"
        @id = SecureRandom.hex(2)
        @hostname = "void-hatch-#{@id}"
      end

      def host
        print " => Adding hostname #{@hostname}..."
        conf = "#{@network_dir}/hostname"
        File.write(conf, "#{@hostname}\n", mode: 'w', chmod: 0744)
        puts "\s[OK]"
      end

      def network
        print ' => Copying /etc/resolv.conf...'
        src = '/etc/resolv.conf'
        dest = "#{@network_dir}/resolv.conf"
        FileUtils.copy_file(src, dest)
        puts "\s[Ok]"
      end

      def system
        print ' => Updating configs system...'
        control_options
        rc = "#{MOUNTPOINT}/etc/rc.conf"
        add_line(rc, 'HARDWARECLOCK="UTC"') unless search(rc, /^HARDWARECLOCK/)
        add_line(rc, "KEYMAP=\"#{OPTIONS[:keymap]}\"") unless search(rc, /^KEYMAP/)
        add_line(rc, "TIMEZONE=\"#{OPTIONS[:zoneinfo]}\"") unless search(rc, /^TIMEZONE/)
        add_line(rc, "HOSTNAME=\"#{@hostname}\"") unless search(rc, /^HOSTNAME/)
        puts "\s[OK]"
      end

      def locale
        print ' => Updating locale system...'
        control_options
        conf = "#{MOUNTPOINT}/etc/locale.conf"
        File.write(conf, "LANG=#{@lang}\n")
        add_line(conf, 'LC_COLLATE=C')
        OPTIONS[:musl] && return

        conf = "#{MOUNTPOINT}/etc/default/libc-locales"
        add_line(conf, @utf8)
        puts "\s[OK]"
        command 'xbps-reconfigure -f glibc-locales'
      end

      private

      def control_options
        search_zone(OPTIONS[:zoneinfo])
        search_utf8(OPTIONS[:language])
        search_key(OPTIONS[:keymap])
      end

      def search_key(keys)
        @keymap = nil
        Dir.glob("#{MOUNTPOINT}/usr/share/kbd/keymaps/**/#{keys}.map.gz") { |f|
          @keymap = f
        }
        raise ArgumentError, "No keymap #{@keymap} found" unless @keymap
      end

      def search_zone(zone)
        unless File.exist? "#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}"
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end

      def search_utf8(lang)
        @utf8, @lang = nil, nil
        File.open("#{MOUNTPOINT}/etc/default/libc-locales").each do |l|
          @utf8 = l.delete_prefix('#') if l.match(/#{lang}.UTF-8/)
          found = l.split if l.match(/#{lang}.UTF-8/)
          @lang = found[0].delete_prefix('#') if found
        end
        @utf8 || @log.fatal("Lang #{lang} no found")
      rescue Errno::ENOENT => e
        OPTIONS[:musl] || @log.fatal(e)
      end
    end
  end
end

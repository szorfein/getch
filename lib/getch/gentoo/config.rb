require 'fileutils'
require 'tempfile'
require 'securerandom'

module Getch
  module Gentoo
    class Config
      def initialize
        @make = "#{MOUNTPOINT}/etc/portage/make.conf"
        @log = Getch::Log.new
      end

      def portage
        nproc = `nproc`.chomp()
        grub_pc = Helpers::efi? ? '' : 'GRUB_PLATFORMS="pc"'
        quiet = DEFAULT_OPTIONS[:verbose] ? '' : "EMERGE_DEFAULT_OPTS=\"--jobs=#{nproc} --load-average=#{nproc}\""

        # Add cpu name
        cpu=`gcc -c -Q -march=native --help=target | grep march | awk '{print $2}' | head -1`.chomp
        @log.debug "CPU found ==> #{cpu}"

        tmp = Tempfile.new('make.conf')

        File.open(@make).each { |l|
          if l.match(/^COMMON_FLAGS/)
            File.write(tmp, "COMMON_FLAGS=\"-march=#{cpu} -O2 -pipe\"\n", mode: 'a')
          else
            File.write(tmp, l, mode: 'a')
          end
          line_count += 1
        }

        FileUtils.copy_file(tmp, @make, preserve = true)

        # Add the rest
        data = [
          '',
          'ACCEPT_KEYWORDS="amd64"',
          "MAKEOPTS=\"-j#{nproc} -l#{nproc}\"",
          quiet,
          'INPUT_DEVICES="libinput"',
          grub_pc
        ]
        File.write(@make, data.join("\n"), mode: "a")
      end

      # Write a repos.conf/gentoo.conf with the gpg verification
      def repo
        src = "#{MOUNTPOINT}/usr/share/portage/config/repos.conf"
        dest = "#{MOUNTPOINT}/etc/portage/repos.conf"
        FileUtils.mkdir dest, mode: 0644 if ! Dir.exist?(dest)
        tmp = Tempfile.new('gentoo.conf')
        line_count = 0

        File.open(src).each { |l|
          File.write(tmp, "sync-allow-hardlinks = yes\n", mode: 'a') if line_count == 2
          if l.match(/^sync-type = rsync/)
            File.write(tmp, "sync-type = webrsync\n", mode: 'a')
          else
            File.write(tmp, l, mode: 'a')
          end
          line_count += 1
        }

        FileUtils.copy_file(tmp, "#{dest}/gentoo.conf", preserve = false)
      end

      def network
        src = '/etc/resolv.conf'
        dest = "#{MOUNTPOINT}/etc/resolv.conf"
        FileUtils.copy_file(src, dest, preserve = false)
      end

      def systemd(options)
        control_options(options)
        File.write("#{MOUNTPOINT}/etc/locale.gen", @utf8)
        File.write("#{MOUNTPOINT}/etc/locale.conf", "LANG=#{@lang}\n")
        File.write("#{MOUNTPOINT}/etc/locale.conf", 'LC_COLLATE=C', mode: 'a')
        File.write("#{MOUNTPOINT}/etc/timezone", "#{options.zoneinfo}")
        File.write("#{MOUNTPOINT}/etc/vconsole.conf", "KEYMAP=#{options.keymap}")
      end

      def hostname
        id = SecureRandom.hex(2)
        File.write("#{MOUNTPOINT}/etc/hostname", "gentoo-hatch-#{id}")
      end

      def portage_fs
        portage = "#{MOUNTPOINT}/etc/portage"
        Helpers::create_dir("#{portage}/package.use")
        Helpers::create_dir("#{portage}/package.accept_keywords")
        Helpers::create_dir("#{portage}/package.unmask")

        Helpers::add_file("#{portage}/package.use/zzz_via_autounmask")
        Helpers::add_file("#{portage}/package.accept_keywords/zzz_via_autounmask")
        Helpers::add_file("#{portage}/package.unmask/zzz_via_autounmask")
      end

      private

      def control_options(options)
        search_zone(options.zoneinfo)
        search_utf8(options.language)
        search_key(options.keymap)
      end

      def search_key(keys)
        @keymap = nil
        Dir.glob("#{MOUNTPOINT}/usr/share/keymaps/**/#{keys}.map.gz") { |f|
          @keymap = f
        }
        raise ArgumentError, "No keymap #{@keymap} found" if ! @keymap
      end

      def search_zone(zone)
        if ! File.exist?("#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}")
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

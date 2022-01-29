require 'nito'
require 'tempfile'

module Getch
  module Config
    class Portage
      include NiTo

      def initialize
        @log = Log.new
        @dest = "#{OPTIONS[:mountpoint]}/etc/portage"
        @usr_s = "#{OPTIONS[:mountpoint]}/usr/share/portage"
        x
      end

      def x
        @log.info "Configuring Portage...\n"
        portage_dir
        gentoo_repo
        cpu_conf
        make_conf
        https_mirror
      end

      protected

      def portage_dir
        mkdir "#{@dest}/package.use", 0744
        mkdir "#{@dest}/package.accept_keywords", 0744
        mkdir "#{@dest}/package.unmask", 0744
        mkdir "#{@dest}/package.license", 0744

        touch "#{@dest}/package.use/zzz_via_autounmask"
        touch "#{@dest}/package.accept_keywords/zzz_via_autounmask"
        touch "#{@dest}/package.unmask/zzz_via_autounmask"
      end

      # Recreate a gentoo.conf from /usr/share/portage/config/repos.conf
      def gentoo_repo
        tmp = Tempfile.new 'gentoo.conf'
        line_n = 0
        mkdir "#{@dest}/repos.conf", 0644
        File.open("#{@usr_s}/config/repos.conf").each do |l|
          echo_a tmp, 'sync-allow-hardlinks = yes' if line_n == 2
          if l.match(/^sync-type = rsync/)
            echo_a tmp, 'sync-type = webrsync'
          else
            File.write tmp, l, mode: 'a'
          end
          line_n += 1
        end
        cp tmp, "#{@dest}/repos.conf/gentoo.conf"
      end

      def cpu_conf
        tmp = Tempfile.new('make.conf')
        cpu = get_cpu
        File.open("#{@dest}/make.conf").each do |l|
          if l.match(/^COMMON_FLAGS/)
            echo_a tmp, "COMMON_FLAGS=\"-march=#{cpu} -O2 -pipe -fomit-frame-pointer\""
          else
            File.write tmp, l, mode: 'a'
          end
        end
        cp tmp, "#{@dest}/make.conf"
      end

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#MAKEOPTS
      def make_conf
        mem = get_memory
        makeopts = mem[0].to_i / 2

        echo_a "#{@dest}/make.conf", 'ACCEPT_KEYWORDS="amd64"'
        echo_a "#{@dest}/make.conf", 'INPUT_DEVICES="libinput"'
        echo_a "#{@dest}/make.conf", "MAKEOPTS=\"-j#{makeopts}\""
      end

      # https://www.gentoo.org/downloads/mirrors/
      def https_mirror
        list = 'https://gentoo.osuosl.org'
        list << ' https://mirrors.rit.edu/gentoo'
        list << ' https://ftp.belnet.be/pub/rsync.gentoo.org/gentoo'
        list << ' https://mirror.init7.net/gentoo'
        echo_a "#{@dest}/make.conf", "GENTOO_MIRRORS=\"#{list}\""
      end

      private

      def get_cpu
        `chroot #{OPTIONS[:mountpoint]} /bin/bash -c \"source /etc/profile ; gcc -c -Q -march=native --help=target | grep march\" | awk '{print $2}' | head -1`.chomp
      end

      def get_memory
        mem = '2048'
        File.open('/proc/meminfo').each do |l|
          t = l.split(' ') if l =~ /memtotal/i
          t && mem = t[1]
        end
        mem
      end
    end
  end
end

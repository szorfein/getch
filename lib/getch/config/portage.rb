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
        license
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
        mkdir "#{@dest}/repos.conf", 0644
        cp "#{@usr_s}/config/repos.conf", "#{@dest}/repos.conf/gentoo.conf"
        sed "#{@dest}/repos.conf/gentoo.conf", /^sync-type/, 'sync-type = webrsync'
      end

      # -fomit-frame-pointer reduce code compiled
      # but have repercussions on the debugging of applications
      def cpu_conf
        change = 'COMMON_FLAGS="-march=native -O2 -pipe -fomit-frame-pointer"'
        sed "#{@dest}/make.conf", /^COMMON_FLAGS/, change
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

      def license
        conf = "#{@dest}/package.license/kernel"
        echo conf, 'sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE'
        echo_a conf, 'sys-firmware/intel-microcode intel-ucode'
      end

      private

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

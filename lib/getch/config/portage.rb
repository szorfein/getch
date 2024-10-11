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
        mkdir "#{@dest}/binrepos.conf", 0744 if OPTIONS[:binary]

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
        change = if OPTIONS[:binary]
                   'COMMON_FLAGS="-O2 -pipe -march=x86-64 -mtune=generic"'
                 else
                   'COMMON_FLAGS="-march=native -O2 -pipe -fomit-frame-pointer"'
                 end
        sed "#{@dest}/make.conf", /^COMMON_FLAGS/, change
      end

      # https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#MAKEOPTS
      # Gentoo binary
      # https://wiki.gentoo.org/wiki/Binary_package_guide
      # https://wiki.gentoo.org/wiki/Gentoo_Binary_Host_Quickstart
      def make_conf
        nproc = `nproc`.chomp

        echo_a "#{@dest}/make.conf", 'ACCEPT_KEYWORDS="amd64"'
        echo_a "#{@dest}/make.conf", 'INPUT_DEVICES="libinput"'
        echo_a "#{@dest}/make.conf", "MAKEOPTS=\"-j#{nproc} -l#{nproc}\""
        return unless OPTIONS[:binary]

        echo_a "#{@dest}/make.conf", 'EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --getbinpkg"'
        echo_a "#{@dest}/make.conf", 'FEATURES="getbinpkg binpkg-request-signature'
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
    end
  end
end

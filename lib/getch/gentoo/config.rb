# frozen_string_literal: true

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
        grub_pc = Helpers.efi? ? '' : 'GRUB_PLATFORMS="pc"'
        nproc = `nproc`.chomp()

        # Add cpu name
        cpu=`chroot #{MOUNTPOINT} /bin/bash -c \"source /etc/profile ; gcc -c -Q -march=native --help=target | grep march\" | awk '{print $2}' | head -1`.chomp
        raise 'Error, no cpu found' unless cpu || cpu == ''

        @log.debug "CPU found ==> #{cpu}"

        tmp = Tempfile.new('make.conf')

        File.open(@make).each { |l|
          if l.match(/^COMMON_FLAGS/)
            File.write(tmp, "COMMON_FLAGS=\"-march=#{cpu} -O2 -pipe -fomit-frame-pointer\"\n", mode: 'a')
          else
            File.write(tmp, l, mode: 'a')
          end
        }

        FileUtils.copy_file(tmp, @make)

        # Add the rest
        data = [
          '',
          "MAKEOPTS=\"-j#{nproc}\"",
          'ACCEPT_KEYWORDS="amd64"',
          'INPUT_DEVICES="libinput"',
          'USE="${USE} audit"',
          grub_pc
        ]
        File.write(@make, data.join("\n"), mode: 'a')
      end

      # Write a repos.conf/gentoo.conf with the gpg verification
      def repo
        src = "#{MOUNTPOINT}/usr/share/portage/config/repos.conf"
        dest = "#{MOUNTPOINT}/etc/portage/repos.conf"
        FileUtils.mkdir dest, mode: 0644 unless Dir.exist?(dest)
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

        FileUtils.copy_file(tmp, "#{dest}/gentoo.conf")
      end

      def network
        src = '/etc/resolv.conf'
        dest = "#{MOUNTPOINT}/etc/resolv.conf"
        FileUtils.copy_file(src, dest)
      end

      def systemd
        control_options
        Helpers.echo "#{MOUNTPOINT}/etc/locale.gen", @utf8
        Helpers.echo "#{MOUNTPOINT}/etc/locale.conf", "LANG=#{@lang}"
        Helpers.echo_a "#{MOUNTPOINT}/etc/locale.conf", 'LC_COLLATE=C'
        File.write("#{MOUNTPOINT}/etc/timezone", "#{Getch::OPTIONS[:zoneinfo]}\n")
        File.write("#{MOUNTPOINT}/etc/vconsole.conf", "KEYMAP=#{Getch::OPTIONS[:keymap]}\n")
      end

      def hostname
        id = SecureRandom.hex(2)
        File.write("#{MOUNTPOINT}/etc/hostname", "gentoo-hatch-#{id}")
      end

      def portage_fs
        portage = "#{MOUNTPOINT}/etc/portage"
        Helpers.mkdir("#{portage}/package.use")
        Helpers.mkdir("#{portage}/package.accept_keywords")
        Helpers.mkdir("#{portage}/package.unmask")

        Helpers.add_file("#{portage}/package.use/zzz_via_autounmask")
        Helpers.add_file("#{portage}/package.accept_keywords/zzz_via_autounmask")
        Helpers.add_file("#{portage}/package.unmask/zzz_via_autounmask")
      end

      # https://wiki.gentoo.org/wiki/Signed_kernel_module_support
      def portage_bashrc
        conf = "#{MOUNTPOINT}/etc/portage/bashrc"
        content = %q{
function pre_pkg_preinst() {
    # This hook signs any out-of-tree kernel modules.
    if [[ "$(type -t linux-mod_pkg_preinst)" != "function" ]]; then
        # The package does not seem to install any kernel modules.
        return
    fi
    # Get the signature algorithm used by the kernel.
    local module_sig_hash="$(grep -Po '(?<=CONFIG_MODULE_SIG_HASH=").*(?=")' "${KERNEL_DIR}/.config")"
    # Get the key file used by the kernel.
    local module_sig_key="$(grep -Po '(?<=CONFIG_MODULE_SIG_KEY=").*(?=")' "${KERNEL_DIR}/.config")"
    module_sig_key="${module_sig_key:-certs/signing_key.pem}"
    # Path to the key file or PKCS11 URI
    if [[ "${module_sig_key#pkcs11:}" == "${module_sig_key}" && "${module_sig_key#/}" == "${module_sig_key}" ]]; then
        local key_path="${KERNEL_DIR}/${module_sig_key}"
    else
        local key_path="${module_sig_key}"
    fi
    # Certificate path
    local cert_path="${KERNEL_DIR}/certs/signing_key.x509"
    # Sign all installed modules before merging.
    find "${D%/}/${INSDESTTREE#/}/" -name "*.ko" -exec "${KERNEL_DIR}/scripts/sign-file" "${module_sig_hash}" "${key_path}" "${cert_path}" '{}' \;
}
        }

        f = File.new(conf, 'w')
        f.write("#{content}\n")
        f.chmod(0700)
        f.close
      end

      private

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
        raise ArgumentError, "No keymap #{@keymap} found" unless @keymap
      end

      def search_zone(zone)
        unless File.exist? "#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}"
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end

      def search_utf8(lang)
        @utf8, @lang = nil, nil
        File.open("#{MOUNTPOINT}/usr/share/i18n/SUPPORTED").each do |l|
          @utf8 = l if l.match(/^#{lang}[. ]+utf-8 /i)
          @lang = $~[0] if l.match(/^#{lang}[. ]+utf-8/i)
        end
        raise ArgumentError, "Lang #{lang} no found" unless @utf8
      end
    end
  end
end

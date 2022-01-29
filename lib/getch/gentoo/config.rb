# frozen_string_literal: true

require 'fileutils'
require 'tempfile'

module Getch
  module Gentoo
    class Config
      def initialize
        @make = "#{MOUNTPOINT}/etc/portage/make.conf"
        @log = Getch::Log.new
        x
      end

      def x
        Getch::Config::Portage.new
        Getch::Config::Locale.new
        Getch::Config::PreNetwork.new
        Getch::Config::Keymap.new
      end

      def systemd
        control_options
        File.write("#{MOUNTPOINT}/etc/timezone", "#{OPTIONS[:zoneinfo]}\n")
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
      end

      def search_zone(zone)
        unless File.exist? "#{MOUNTPOINT}/usr/share/zoneinfo/#{zone}"
          raise ArgumentError, "Zoneinfo #{zone} doesn\'t exist."
        end
      end
    end
  end
end

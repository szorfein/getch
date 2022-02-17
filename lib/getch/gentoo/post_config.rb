# frozen_string_literal: true

require 'nito'

module Getch
  module Gentoo
    class PostConfig
      include NiTo

      def initialize
        @make = "#{OPTIONS[:mountpoint]}/etc/portage/make.conf"
        x
      end

      protected

      def x
        Getch::Config::Locale.new
        Getch::Config::Keymap.new
        Getch::Config::TimeZone.new
        cpuflags
        Gentoo::UseFlag.new
        grub
      end

      protected

      def cpuflags
        conf = "#{OPTIONS[:mountpoint]}/etc/portage/package.use/00cpuflags"
        Install.new('app-portage/cpuid2cpuflags')
        cpuflags = Chroot.new('cpuid2cpuflags')
        File.write(conf, "*/* #{cpuflags}\n")
      end

      def grub
        grub_pc = Helpers.efi? ? 'GRUB_PLATFORMS="efi-64"' : 'GRUB_PLATFORMS="pc"'
        echo_a "#{OPTIONS[:mountpoint]}/etc/portage/make.conf", grub_pc
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
    end
  end
end

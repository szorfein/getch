# frozen_string_literal: true

module Getch
  # configurations for the new system
  module Config
    def sysctl
      pwd = File.expand_path(__dir__)
      dest = "#{Getch::MOUNTPOINT}/etc/sysctl.d/"

      mkdir dest
      Helpers.cp("#{pwd}/../../assets/network-stack.conf", dest)
      Helpers.cp("#{pwd}/../../assets/system.conf", dest)
    end
  end
end

require_relative 'config/portage'
require_relative 'config/locale'
require_relative 'config/pre_network'
require_relative 'config/keymap'
require_relative 'config/timezone'
require_relative 'config/grub'
require_relative 'config/account'
require_relative 'config/iwd'
require_relative 'config/dhcp'

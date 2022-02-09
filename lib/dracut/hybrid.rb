# frozen_string_literal: true

module Dracut
  class Hybrid < Encrypt
    def initialize(devs, options)
      super
      @vg = options[:vg_name] ||= 'vg0'
    end

    def get_line
      root = Getch::Helpers.uuid @root
      boot = Getch::Helpers.uuid @boot
      "rd.luks.uuid=#{root} rd.luks.uuid=#{boot} rd.lvm.vg=#{@vg} root=/dev/#{@vg}/root"
    end
  end
end

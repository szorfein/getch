# frozen_string_literal: true

module Dracut
  class Lvm < Root
    def initialize(devs, options)
      super
      @vg = options[:vg_name] ||= 'vg0'
    end

    def get_line
      "rd.lvm.vg=#{@vg} root=/dev/#{@vg}/root resume=/dev/#{@vg}/swap"
    end
  end
end

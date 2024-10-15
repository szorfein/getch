# frozen_string_literal: true

module Fstab
  # Generating fstab for zfs filesystem
  class Zfs < Root
    def initialize(devs, options)
      super
      @encrypt = options[:encrypt]
    end

    def generate
      @log.info 'Generating fstab...'
      write_efi
      write_swap
      @log.result_ok
    end

    def write_swap
      uuid = gen_uuid @swap
      line = if @encrypt
               '/dev/mapper/swap-luks none swap sw 0 0'
             else
               "UUID=#{uuid} swap swap rw,noatime,discard 0 0"
             end
      echo_a @conf, line
    end
  end
end

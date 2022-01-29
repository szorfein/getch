# frozen_string_literal: true

require 'nito'

module Getch
  module Config
    # Search and configure the keymap (man loadkeys)
    class Keymap
      include NiTo

      def initialize
        @log = Log.new
        @rc_conf = "#{OPTIONS[:mountpoint]}/etc/rc.conf"
        @vconsole_conf = "#{OPTIONS[:mountpoint]}/etc/vconsole.conf"
        @conf_d = "#{OPTIONS[:mountpoint]}/etc/conf.d/keymaps"
        @keymaps_dir = nil
        @keymap = nil
        x
      end

      protected

      def x
        @log.info "Configuring keymap...\n"
        search_keymap
        apply_conf
      end

      def search_keymap
        search_dir
        path = "#{OPTIONS[:mountpoint]}#{@keymaps_dir}/**/#{OPTIONS[:keymap]}.map.gz"
        Dir.glob(path) { |f| @keymap = OPTIONS[:keymap] if f }

        @keymap || @log.fatal("No keymap found for #{OPTIONS[:keymap]}.")
      end

      def apply_conf
        @log.info "Setting keymap to \"#{@keymap}\"...\t\t\t"
        writing_rc_conf
        writing_vconsole_conf
        writing_conf_d_keymaps
        @log.result 'Ok'
      end

      def writing_rc_conf
        return unless File.exist? @rc_conf

        echo_a @rc_conf, "KEYMAP=\"#{@keymap}\""
      end

      def writing_vconsole_conf
        return unless Helpers.systemd?

        echo_a @vconsole_conf, "KEYMAP=\"#{@keymap}\""
      end

      def writing_conf_d_keymaps
        return unless File.exist? @conf_d

        sed @conf_d, /^keymap=/, "keymap=\"#{@keymap}\""
      end

      private

      def search_dir
        case OPTIONS[:os]
        when 'gentoo' then @keymaps_dir = '/usr/share/keymaps'
        when 'void' then @keymaps_dir = '/usr/share/kbd/keymaps'
        else
          @log.fatal('OPTIONS[:os] not supported yet.')
        end

        File.exist? "#{OPTIONS[:mountpoint]}#{@keymaps_dir}" ||
          @log.fatal("No dir keymaps #{@keymaps_dir} found.")
      end
    end
  end
end

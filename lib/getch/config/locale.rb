# frozen_string_literal: true

require 'nito'

# Gentoo: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Locale_generation
# Void: https://docs.voidlinux.org/config/locales.html#locales-and-translations
module Getch
  module Config
    class Locale
      include NiTo

      # Gentoo use i18n_supported
      # Void use libc_locale
      def initialize
        @log = Log.new
        @i18n_supported = "#{OPTIONS[:mountpoint]}/usr/share/i18n/SUPPORTED"
        @libc_locales = "#{OPTIONS[:mountpoint]}/etc/default/libc-locales"
        @locale_conf = "#{OPTIONS[:mountpoint]}/etc/locale.conf"
        @i18n = nil
        @lang = nil
        x
      end

      def x
        @log.info "Configuring locales...\n"
        search_locale
        apply_conf
      end

      protected

      def search_locale
        search_i18n
        search_libc
        lang
      end

      def apply_conf
        return if OPTIONS[:musl]

        File.exist?("#{OPTIONS[:mountpoint]}/etc/locale.gen") && write_locale_gen
        File.exist?(@libc_locales) && write_libc_locales
      end

      def write_locale_gen
        @log.fatal("No UTF8 locale found for #{OPTIONS[:language]}") unless @i18n

        @log.info "Using locale #{@i18n}...\n"
        echo "#{OPTIONS[:mountpoint]}/etc/locale.gen", @i18n
        locale_conf
        Getch::Chroot.new('locale-gen')
      end

      def write_libc_locales
        @log.fatal("No UTF8 locale found for #{OPTIONS[:language]}") unless @i18n

        @log.info "Using locale #{@i18n}...\n"
        echo @libc_locales, @i18n
        locale_conf
        Getch::Chroot.new('xbps-reconfigure -f glibc-locales')
      end

      private

      def search_i18n
        return unless File.exist? @i18n_supported

        File.open(@i18n_supported).each do |l|
          @i18n = l.chomp if l =~ /#{OPTIONS[:language]}.*UTF-8$/
        end
      end

      def search_libc
        return unless File.exist? @libc_locales

        File.open(@libc_locales).each do |l|
          @i18n = l.tr('#', '').chomp if l =~ /\#?#{OPTIONS[:language]}.*UTF-8/
        end
      end

      def lang
        return unless @i18n

        lang = @i18n.split(' ')
        @lang = lang[0]
      end

      def locale_conf
        echo @locale_conf, "LANG=#{@lang}"
        echo_a @locale_conf, 'LC_COLLATE=C.UTF-8'
      end
    end
  end
end

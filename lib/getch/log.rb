# frozen_string_literal: true

require 'logger'

module Getch
  class Log

    WHITE   = "\033[37m"
    CYAN    = "\033[36m"
    MAGENTA = "\033[35m"
    BLUE    = "\033[34m"
    YELLOW  = "\033[33m"
    GREEN   = "\033[32m"
    RED     = "\033[31m"
    BLACK   = "\033[30m"
    BOLD    = "\033[1m"
    CLEAR   = "\033[0m"

    def initialize(verbose = false)
      @log_file = '/tmp/log_install.txt'
      @verbose = verbose
      check_file
      init_log
      init_log_text
    end

    def info(msg)
      log_info(msg)
      @logger_text.info(msg)
    end

    def error(msg)
      @logger.error(msg)
      @logger_text.error(msg)
    end

    def debug(msg)
      @logger.debug(msg)
      @logger_text.debug(msg)
    end

    def fatal(msg)
      @logger.fatal(msg)
      @logger_text.fatal(msg)
    end

    protected

    def log_info(text)
      logger = Logger.new $stdout, level: 'INFO'
      logger.formatter = proc do | severity, _, _, msg |
        "#{BOLD}#{severity[0]}#{CLEAR}#{msg}"
      end

      logger.info "#{GREEN}#{BOLD} >>> #{CLEAR}#{WHITE}#{text}#{CLEAR}"
    end

    private

    def check_file
      puts "Creating log at #{@log_file}" unless File.exist? @log_file
    end

    def init_log
      @logger = Logger.new($stdout)
      @logger.level = @verbose ? Logger::DEBUG : Logger::INFO
      @logger.formatter = proc { |severity, _, _, msg|
        "#{severity}, #{msg}\n"
      }
    end

    def init_log_text
      @logger_text = Logger.new(@log_file, 1)
      @logger_text.level = Logger::DEBUG
      @logger_text.formatter = proc { |severity, datetime, _, msg|
        "#{severity}, #{datetime}, #{msg}\n" 
      }
    end
  end
end

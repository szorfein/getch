require 'logger'

module Getch
  class Log
    def initialize(verbose = false)
      @log_file = '/tmp/log_install.txt'
      @verbose = verbose
      check_file
      init_log
      init_log_text
    end

    def info(msg)
      @logger.info(msg)
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

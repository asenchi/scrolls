require 'syslog'

module Scrolls
  class SyslogLogger
    def initialize(ident = 'scrolls', facility = Syslog::LOG_USER)
      options = Syslog::LOG_PID|Syslog::LOG_CONS
      if Syslog.opened?
        @syslog = Syslog.reopen(ident, options, facility)
      else
        @syslog = Syslog.open(ident, options, facility)
      end
    end

    def puts(data)
      @syslog.log(Syslog::LOG_INFO, "%s", data)
    end

    def self.opened?
      Syslog.opened?
    end
  end
end

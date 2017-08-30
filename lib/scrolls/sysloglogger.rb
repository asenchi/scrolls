module Scrolls
  class SyslogLogger
    def initialize(ident = 'scrolls', facility = Scrolls::LOG_FACILITY)
      options = Scrolls::SYSLOG_OPTIONS
      if Syslog.opened?
        @syslog = Syslog.reopen(ident, options, facility)
      else
        @syslog = Syslog.open(ident, options, facility)
      end
    end

    def log(data)
      @syslog.log(Syslog::LOG_INFO, "%s", data)
    end

    def self.opened?
      Syslog.opened?
    end
  end
end

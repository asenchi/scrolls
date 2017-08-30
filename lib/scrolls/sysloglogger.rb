module Scrolls
  class SyslogLogger
    def initialize(ident = 'scrolls',
                   options = Scrolls::SYSLOG_OPTIONS,
                   facility = Scrolls::LOG_FACILITY)
      if Syslog.opened?
        @syslog = Syslog.reopen(ident, options, facility)
      else
        @syslog = Syslog.open(ident, options, facility)
      end
    end

    def log(data)
      @syslog.log(Syslog::LOG_INFO, "%s", data)
    end
  end
end

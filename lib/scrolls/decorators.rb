require "scrolls"

module Scrolls

  module Decorators

    def self.included(klass)
      klass.extend ClassMethods
    end

    module Convertions
    private

      def hashfied_list(list)
        return {} if list.empty?
        list.inject({}) do |h, item|
          h[item.to_sym] = true
          h
        end
      end

      def log_data_as_hash(*data)
        last = data.pop
        return {} unless last
        return hashfied_list(data).merge(last) if last.kind_of?(Hash)
        data.push(last)
        hashfied_list(data)
      end

    end

    module ClassMethods
      include Scrolls::Decorators::Convertions

      def log_context(*decoration)
        @__log_context__ = log_data_as_hash(*decoration) unless decoration.empty?
        @__log_context__ ||= {}
      end

      def log(*decoration)
        @__log_decoration__ = log_data_as_hash(*decoration)
      end

      def method_added(method_name)
        return unless @__log_decoration__
        decoration = log_context.merge(@__log_decoration__)
        @__log_decoration__ = nil

        class_name = self.name
        old_method = instance_method(method_name)
        define_method(method_name) do |*args, &blk|
          Log.log(decoration.merge(class: class_name, method: method_name)) do
            old_method.bind(self).call(*args, &blk)
          end
        end
      end

    end

    include Convertions

    # Simpler log method that accepts a list of tags and a log data hash
    #
    # == Parameters
    #
    # data = *tags, hash
    #
    # == Example
    #
    #    log "component", "subcomponent", release: "v1", at: "start"
    #
    def log(*data)
      hash = log_data_as_hash(*data)
      Log.log(prepend_log_context(hash))
    end

    # See #log
    def log_exception(e, *data)
      hash = log_data_as_hash(*data)
      Log.log_exception(prepend_log_context(hash), e)
    end


  private

    def prepend_log_context(data)
      self.class.log_context.merge(data)
    end

  end
end


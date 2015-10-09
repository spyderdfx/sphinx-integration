# coding: utf-8
require 'sphinx/integration/extensions/thinking_sphinx/indexing_mode'

module Sphinx::Integration::Extensions::ThinkingSphinx
  autoload :ActiveRecord, 'sphinx/integration/extensions/thinking_sphinx/active_record'
  autoload :Attribute, 'sphinx/integration/extensions/thinking_sphinx/attribute'
  autoload :BundledSearch, 'sphinx/integration/extensions/thinking_sphinx/bundled_search'
  autoload :Index, 'sphinx/integration/extensions/thinking_sphinx/index'
  autoload :PostgreSQLAdapter, 'sphinx/integration/extensions/thinking_sphinx/postgresql_adapter'
  autoload :Property, 'sphinx/integration/extensions/thinking_sphinx/property'
  autoload :Search, 'sphinx/integration/extensions/thinking_sphinx/search'
  autoload :Source, 'sphinx/integration/extensions/thinking_sphinx/source'
  autoload :Configuration, 'sphinx/integration/extensions/thinking_sphinx/configuration'
  autoload :LastIndexingTime, 'sphinx/integration/extensions/thinking_sphinx/last_indexing_time'

  extend ActiveSupport::Concern

  included do
    DEFAULT_MATCH = :extended2
    include Sphinx::Integration::FastFacet
    include LastIndexingTime

    class << self
      attr_writer :logger
    end
  end

  module ClassMethods
    def max_matches
      @ts_max_matches ||= ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
    end

    def reset_indexed_models
      context.indexed_models.each do |model|
        model.constantize.reset_indexes
      end
    end

    def error(exception_or_message, severity = ::Logger::ERROR)
      if exception_or_message.is_a?(::Exception)
        log(exception_or_message.message, severity)
        debug(exception_or_message.backtrace.join("\n"))
      else
        log(exception_or_message, severity)
      end
    end

    def fatal(exception_or_message)
      error(exception_or_message, ::Logger::FATAL)
    end

    def debug(message)
      log(message, ::Logger::DEBUG)
    end

    def warn(message)
      log(message, ::Logger::WARN)
    end

    def log(message, severity = ::Logger::INFO)
      message.to_s.split("\n").each { |m| logger.add(severity, m) if m.present? }

      return unless block_given?

      begin
        yield
      rescue Exception => exception
        fatal(exception)
        raise
      end
    end

    alias_method :info, :log

    def logger
      @logger ||= ::Logger.new(Rails.root.join("log", "sphinx.log")).tap do |logger|
        logger.formatter = ::Logger::Formatter.new
        logger.level = ::Logger.const_get(::ThinkingSphinx::Configuration.instance.log_level.upcase)
      end
    end
  end
end

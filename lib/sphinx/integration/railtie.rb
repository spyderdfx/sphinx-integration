# coding: utf-8
require 'rails'
require 'thinking-sphinx'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie

    initializer 'sphinx_integration.configuration', :before => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx::Configuration.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
      ThinkingSphinx.database_adapter = :postgresql
    end

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      [
        Riddle::Query::Insert,
        Riddle::Query::Select,
        Riddle::Configuration,
        Riddle::Client,
        ThinkingSphinx,
        ThinkingSphinx::Configuration,
        ThinkingSphinx::Attribute,
        ThinkingSphinx::Source,
        ThinkingSphinx::BundledSearch,
        ThinkingSphinx::Index::Builder,
        ThinkingSphinx::Property,
        ThinkingSphinx::Search,
        ThinkingSphinx::Index,
        ThinkingSphinx::PostgreSQLAdapter
      ].each do |klass|
        klass.send :include, "Sphinx::Integration::Extensions::#{klass.name}".constantize
      end

      ActiveSupport.on_load :active_record do
        include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
      end
    end

    initializer 'sphinx_integration.rspec' do
      if defined?(::RSpec)
        require 'rspec/version'
        if Gem::Version.new(RSpec::Version::STRING) >= Gem::Version.new('3.0.0')
          RSpec.configure do |c|
            c.before(:each) do |example|
              unless example.metadata.fetch(:with_sphinx, false)
                Sphinx::Integration::Transmitter.write_disabled = true
              end
            end

            c.after(:each) do |example|
              if example.metadata.fetch(:with_sphinx, false)
                Sphinx::Integration::Helper.new.truncate_rt_indexes
              else
                Sphinx::Integration::Transmitter.write_disabled = false
              end
            end
          end
        else
          RSpec.configure do |c|
            c.before(:each) do
              unless example.metadata.fetch(:with_sphinx, false)
                Sphinx::Integration::Transmitter.write_disabled = true
              end
            end

            c.after(:each) do
              if example.metadata.fetch(:with_sphinx, false)
                Sphinx::Integration::Helper.new.truncate_rt_indexes
              else
                Sphinx::Integration::Transmitter.write_disabled = false
              end
            end
          end
        end
      end
    end

    config.after_initialize do
      ThinkingSphinx.context.define_indexes
    end

    rake_tasks do
      load 'sphinx/integration/tasks.rake'
    end
  end
end

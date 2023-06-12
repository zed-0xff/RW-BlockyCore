# frozen_string_literal: true
require 'yaml'

module CONFIG
  DATA = YAML::load_file(File.join(File.dirname(__FILE__), "..", "config.yml"))

  class << self
    def assets_dir
      @assets_dir ||= File.expand_path(DATA['assets_dir'])
    end

    def ignores
      @ignores ||= DATA['ignore'].map{ |x| Regexp.new(x) }
    end

    def render_types
      @render_types ||= DATA['render_types'].map{ |k,v| [Regexp.new(k),v] }.to_h
    end

    def [] k
      DATA[k]
    end
  end
end

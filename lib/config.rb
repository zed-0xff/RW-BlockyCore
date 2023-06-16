# frozen_string_literal: true
require 'yaml'
require 'zpng'

module CONFIG
  DATA = YAML::load_file(File.join(File.dirname(__FILE__), "..", "config.yml"))

  class << self
    def asset_dirs
      @asset_dirs ||= DATA['asset_dirs'].map{ |x| File.expand_path(x) }
    end

    def ignores
      @ignores ||= DATA['ignore'].map{ |x| Regexp.new(x) }
    end

    def render_types
      @render_types ||= DATA['render_types'].map{ |k,v| [Regexp.new(k),v] }.to_h
    end

    def stuffable_color_corr
      @corr ||= ZPNG::Color.from_grayscale(DATA['stuffable_color_corr'])
    end

    def [] k
      DATA[k]
    end
  end
end

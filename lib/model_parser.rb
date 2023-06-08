#!/usr/bin/env ruby
require_relative 'model'
require_relative 'model_renderer'
require_relative 'def_maker'

require 'active_support/core_ext/string'

class ModelParser
  def initialize type
    @render_types = {}
    @defmaker = DefMaker.new
    @type = type
  end

  def process! mask = "*"
    Dir[File.join(CONFIG.assets_dir, "minecraft/models/#{@type}/#{mask}.json")].each do |fname|
      begin
        process_model fname
      rescue
        STDERR.puts "[!] error processing #{fname}".red
        raise
      end
    end

    File.write "render_types.yml", @render_types.sort_by(&:first).to_h.to_yaml
  end

  def process_model fname
    name = File.basename(fname, ".json")
    key = File.join(@type, name)

    if CONFIG.ignores.any?{ |re| re.match(key) }
      #puts "[-] #{key}".gray
      return
    end

    puts "[.] #{key}"
    model = Model.find(key)
    return if model.abstract?

    unless model.render_types
      renderer = ModelRenderer.new(model, '')
      renderer.detect_render_type
      return if model.abstract?
    end

    model.render_types.each do |suffix, rtype|
      name2 = name + suffix
      defName = @defmaker.name2defName(name2.camelize)
      released = @defmaker.released?(defName)

      renderer = ModelRenderer.new(model, suffix)
      images = renderer.render_all
      dst_dir = File.join("Textures", "Blocky", (released ? "" : "Alpha"), name2[0].upcase)
      FileUtils.mkdir_p dst_dir

      if images.size == 1
        dst_fname = File.join(dst_dir, name2.camelize) + ".png"
        img = images.values[0]
        return if img.nil?
        img.save(dst_fname)
      else
        images.each do |side, img|
          dst_fname = File.join(dst_dir, name2.camelize) + "_#{side}.png"
          img.save(dst_fname)
        end
      end

      @render_types[name2] = rtype.to_s
    end

  rescue Model::NoTextureError
  end
end

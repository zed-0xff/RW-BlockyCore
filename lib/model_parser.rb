#!/usr/bin/env ruby
require_relative 'model'
require_relative 'model_renderer'
require_relative 'def_maker'

require 'active_support/core_ext/string'

class ModelParser
  def initialize
    @render_types = {}
    @defmaker = DefMaker.new
  end

  def process!
    Dir[File.join(CONFIG.assets_dir, "minecraft/models/block/*.json")].each do |fname|
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
    if CONFIG.ignores.any?{ |re| re.match(name) }
      #puts "[-] #{name}".gray
      return
    end

    key = "block/" + name
    puts "[.] #{key}"
    model = Model.find(key)
    return if model.abstract?

    renderer = ModelRenderer.new(model)
    renderer.detect_render_type unless model.render_type
    return if model.abstract?

    defName = @defmaker.name2defName(name.camelize)
    released = @defmaker.released?(defName)

    images = renderer.render_all
    dst_dir = File.join("Textures", "Blocky", (released ? "" : "Alpha"), name[0].upcase)
    FileUtils.mkdir_p dst_dir

    if images.size == 1
      dst_fname = File.join(dst_dir, name.camelize) + ".png"
      img = images.values[0]
      return if img.nil?
      img.save(dst_fname)
    else
      images.each do |side, img|
        dst_fname = File.join(dst_dir, name.camelize) + "_#{side}.png"
        img.save(dst_fname)
      end
    end

    @render_types[model.name] = model.render_type.to_s
  rescue Model::NoTextureError
  end
end

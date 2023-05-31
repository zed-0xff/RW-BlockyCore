#!/usr/bin/env ruby
require 'json'
require 'yaml'
require 'awesome_print'
require 'set'

require_relative "texture_converter"
require_relative "model"

class ModelParser
  GOOD_KEYS = Set.new(%w'side top back front up end all texture east north south west inside content')

  def initialize assets_dir
    @assets_dir = assets_dir
    @was = {}
    @tree = {}
    config = YAML.load_file "config.yml"
    @ignores = config['ignore'].map{ |x| Regexp.new(x) }
    @render_types = {}
    config['render_types'].each do |k,v|
      @render_types[Regexp.new(k)] = v.to_sym
    end

    Dir[File.join(@assets_dir, "minecraft/models/block/*.json")].each do |fname|
      name = "block/" + File.basename(fname, ".json")
      @tree[name] = JSON.parse(File.read(fname))
    end
  end

  def resolve key
    raise key.inspect if key.is_a?(Hash)
    key = key.sub(/^minecraft:/, '')
    r = @tree[key]
    if !r
      puts "[?] no key for #{key}".yellow
      return nil
    end
    if r['parent'].is_a?(String)
      r['parent_name'] = r['parent']
      r['parent'] = resolve(r['parent'])
    end
    r
  end

  def resolve_textures branch
    #puts "[d] br: #{branch}"
    parent_tex = branch['parent'] ? resolve_textures(branch['parent']) : {}
    #puts "[d] pt: #{parent_tex}"
    r = parent_tex.merge(branch['textures'] || {}).dup
    e = parent_tex['elements'] || branch['elements']
    #puts "[d] e: #{e}"
    r['elements'] = e if e
    r
  end

  def log textures, item_key
    keys = textures.keys - %w'particle pane edge'
    return if keys.empty?
    return if keys.map{ |k| textures[k] }.all?{ |x| x.to_s[0] == '#' }

    if textures['elements']
      textures['elements'] = textures['elements'].size
    end

    s = textures.to_s
    return if @was[s]
    @was[s] = item_key

    puts "[-] #{item_key}: #{s}".red
  end

  def export_item k, debug: false
    name = File.basename(k.sub('minecraft:',''))
    if @ignores.any?{ |re| re.match(name) }
      puts "[-] #{k}".gray
      return
    end

    model = Model.new(k, @tree[k])

    model_info = resolve(k) || raise("no model: #{k}")
    pp model_info if debug

    textures = resolve_textures(model_info)
#    pp textures if debug
    if textures.size == 0
      return
    end

    flat = nil
    faces = nil

    if textures['elements']
      efrom = textures.dig('elements', 0, 'from')
      eto   = textures.dig('elements', 0, 'to')

      if efrom && eto
        flat = (efrom == [0, 0, 0] && eto == [16, 16, 16])
      end

      if textures['elements'].size == 1
        faces = textures.dig('elements', 0, 'faces')
        #puts "[d] #{k}: #{faces}" if faces.size == 2
        faces.each do |fk, fv|
          if "##{fk}" != fv['texture']
            #printf "    %-6s: %s\n", fk, fv.inspect
            tex_id = fv['texture'][1..-1]
            if textures[tex_id]
              textures[fk] = textures[tex_id]
            else
              puts "[?] #{k}: no texture #{fk}".yellow
            end
          end
        end
      else
        puts "[?] #{name}: too many elements (#{textures['elements'].size})".yellow
#        return
      end
      textures.delete('elements')
    end

    keys = textures.keys
    keys.delete_if{ |x| !GOOD_KEYS.include?(x) }
    if keys.size == 0
      return
    end

    return if textures.values.all?{ |x| x[0] == '#' }

    args = {}
    extra_tex = {}
    textures.each do |type, tex|
      while tex[0] == '#'
        tex = textures[tex[1..-1]]
      end

      fname = File.join(@assets_dir, "minecraft/textures", tex.sub('minecraft:','').tr(":","/") + ".png")
      raise "no #{fname}" unless File.exist?(fname)

      case type
      when 'side', 'top', 'back', 'front', 'all', 'texture', 'east', 'north', 'south', 'west'
        args[type.to_sym] = fname
      when 'up'
        args[:top] = fname
      when 'end' #, 'platform'
        args[:top] ||= fname
      when 'inside', 'content'
        extra_tex[type.to_sym] = fname
      when 'particle', 'bottom', 'down'
        # nop
      else
        puts "[?] #{k}: unhandled texture type: #{type}".yellow
        extra_tex[type.to_sym] = fname
      end
    end

    if args.size == 1 && args[:back]
      puts "[?] #{args}".yellow
      return
    end

    # scan list of regexps and find first matching
    render_type = @render_types.find{ |x| x[0].match(name) }&.last&.to_sym
    if render_type.nil? && !flat.nil?
      render_type = flat ? :flat : :model
    end

    if name =~ /_horizontal$/
      args[:north] = args[:south] = args[:top]
      args[:top] = args[:east]
      faces = {
        'top' =>  { 'rotation' => 90 },
        'east' => { 'rotation' => 90,  scale_x: 2, scale_y: 4 },
        'west' => { 'rotation' => 270, scale_x: 2, scale_y: 4 },
      }
      render_type = :table
    end

    model.render_type = render_type
    if debug 
      STDOUT << "[d] model: "
      pp model
    end

    if render_type == :flat && args.values.uniq.size == 1
      args = { top: args.values.uniq.first } # flatten
    end
    TextureConverter.convert_args! args, name, flat: flat, debug: debug, extra_tex: extra_tex, faces: faces, render_type: render_type
  end # export_item

  def process!
    @tree.keys.sort.each do |k|
      export_item k
    end
  end
end

if __FILE__ == $0
  p = ModelParser.new( File.expand_path("~/games/minecraft/assets") )
  ARGV.each do |arg|
    arg = "block/#{arg}" unless arg['block/']
    p.export_item arg, debug: true
  end
end

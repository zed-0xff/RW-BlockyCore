#!/usr/bin/env ruby
require 'json'
require 'awesome_print'
require 'set'

require_relative "texture_converter"

class ModelParser
  GOOD_KEYS = Set.new(%w'side top back front up end all texture east north south west inside content')

  def initialize assets_dir
    @assets_dir = assets_dir
    @was = {}
    @tree = {}
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
    r = parent_tex.merge(branch['textures'] || {})
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
    #v = @tree[k]
    #return unless v['textures']
    return if k =~ /_[nsew]+$/
    return if k =~ /_(slab|stairs|pressure_plate|trapdoor|button|fence|leaves|base|age\d)/
    return if k =~ /template_|grindstone/

    return if k =~ /dispenser_vertical|dropper_vertical|sunflower|root|azalea|dripleaf|stripped|grass|froglight|template|scaffold|sculk|daylight|chiseled_bookshelf|stonecutter|candle|turtle_egg|anvil|jigsaw|command_block|comparator|chorus|brewing_stand|repeater|sea_pickle|cake|dragon_egg|chain/
    return if k =~ /_(stem|inventory|alt)$/

    return if k =~ /_wall_(post|side)/ # walls with different heights or smth
    return if k =~ /lightning_rod|end_portal_frame_filled|lectern|_(noside|level|height|contents)\d/ # multiple textures with shift
    return if k =~ /^bell_/
    return if k =~ /:bell_/
    return if k =~ /_door_(bottom|top)/

    model = resolve(k) || raise("no model: #{k}")
    pp model if debug

    textures = resolve_textures(model)
    pp textures if debug
    if textures.size == 0
      return
    end

    faces = nil
    #puts "[d] textures:#{textures}"
    if textures['elements']
      if true # textures['elements'].to_s[", 16, 16]"]
        #puts "[*] #{k}: continue despite having elements".yellow
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
        end
        textures.delete('elements')
      else
        log textures, k
        return
      end
    end

    keys = textures.keys
    keys.delete_if{ |x| !GOOD_KEYS.include?(x) }
    if keys.size == 0
      return
    end

    return if textures.values.all?{ |x| x[0] == '#' }

    #  kt = keys.map{ |x| [x, textures[x]].join(":") }.sort.join(' ')
    #  return if @h1[kt]
    #  @h1[kt] = true

    #n += 1
    #stats[keys.sort.join(" ")] += 1

    #  puts "[.] #{k}: #{textures}"
    #  textures.each do |type, tex|
    #    printf "    %10s: %s\n", type, tex
    #  end

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

    name = File.basename(k.sub('minecraft:',''))
    flat = faces && (faces.size >= 1) && (faces.size <= 2)
    flat ||= name =~ /_(planks|ore|carpet)$/ || name =~ /^(ladder|spawner)$/ || name =~ /^(farmland.*|mud|clay)$/ || name =~ /(soil|sand|dirt)$/
    flat ||= name =~ /_glass|glass_/ || name == 'glass'

    if name =~ /_horizontal$/
      args[:north] = args[:south] = args[:top]
      args[:top] = args[:east]
      faces = {
        'top' =>  { 'rotation' => 90 },
        'east' => { 'rotation' => 90,  scale_x: 2, scale_y: 4 },
        'west' => { 'rotation' => 270, scale_x: 2, scale_y: 4 },
      }
      flat = false
    end

    if flat && args.values.uniq.size == 1
      args = { top: args.values.uniq.first } # flatten
    end
    TextureConverter.convert_args! args, name, flat: flat, debug: debug, extra_tex: extra_tex, faces: faces
  end # export_item

  def process!
    @tree.keys.sort_by(&:size).each do |k|
      export_item k
    end
  end
end

if __FILE__ == $0
  p = ModelParser.new( File.expand_path("~/games/minecraft/assets") )
  ARGV.each do |arg|
    p.export_item arg, debug: true
  end
end

# frozen_string_literal: true
require 'active_support/core_ext/string'
require 'digest/md5'
require 'nokogiri'
require 'set'

class DefMaker
  def initialize
    @was = {}
    @designators = Hash.new(0)

    @lines = [%Q|<?xml version="1.0" encoding="utf-8" ?>|]
    @lines << "<Defs>"
  end

  def process!
    Dir["Textures/Blocky/?/*.png"].each do |fname|
      add_def_from_texture(fname)
    end
    write! "Defs/All.xml"
  end

  def indent(s, n)
    s.gsub(/^/, " "*n)
  end

  def write! fname
    nTotal = 0
    @designators.sort_by(&:last).each do |defName, nItems|
      nTotal += nItems
      printf "[*] %3d items in %s\n", nItems, defName
      add_def <<~EOF
        <DesignatorDropdownGroupDef>
          <defName>#{defName}</defName>
        </DesignatorDropdownGroupDef>
      EOF
    end
    printf "[*] %3d items total\n", nTotal

    @lines << "</Defs>"
    File.write fname, @lines.join("\n")
  end

  def name2designator name
    case name
    when 'Bookshelf', /^Barrel/, 'Jukebox', 'NoteBlock', /Lamp/, /Hopper/, /Cauldron/
      "Blocky_Props_Furniture"
    when /Door/
      "Blocky_Props_Doors"
    when /Trapdoor/
      "Blocky_Props_Trapdoors"
    when /Fence/
      "Blocky_Props_Fences"
    when /Ore$/
      "Blocky_Props_Ores"
    when /Bricks$/, /Tiles$/
      "Blocky_Props_Bricks"
    when /Planks$/, /Mosaic$/
      "Blocky_Props_Planks"
    when /Wool$/
      "Blocky_Props_Wool"
    when /Carpet$/
      "Blocky_Props_Carpet"
    when /Potted/
      "Blocky_Props_Potted"
    when /Farmland/, /Soil$/, 'Mud', /Sand$/, 'Clay', /Dirt$/
      "Blocky_Props_Soil"
    when /Wood$/, /Log$/, /LogHorizontal/
      "Blocky_Props_Wood"
    when /^Bee/, /Melon/, 'Cactus', /Pumpkin/, /HayBlock/, 'HoneyBlock', 'JackOLantern', /Stage\d/, /Age\d/, 'Composter', /NetherWart/, /Mushroom$/
      "Blocky_Props_Garden"
    when /Leaves/, /Vine/
      "Blocky_Props_Leaves"
    when /Lilac|Lily|Azalea|[fF]lower|Poppy|Dandelion|Tulip|Blossom|Daisy|Rose|Bluet|Allium|Sprout|Orchid|Peony/
      "Blocky_Props_Grass"
    when /Coral|Bush|Propagule|Bud$|Fan$|Lichen|Root|Kelp|Plant|Seagrass|Fern|Dripleaf|Sapling|Grass|Fungus/
      "Blocky_Props_Grass"
    when /Glass/
      "Blocky_Props_Glass"
    when 'Andesite', 'Diorite', 'Deepslate', 'Bedrock', 'Calcite', 'EndStone', 'Obsidian', 'Prismarine', /^Polished/, 'Stone', 'Tuff', 'Granite', 'Gravel', 'Cobblestone'
      "Blocky_Props_StonyA"
    when /^Structure/, /CommandBlock/, 'Jigsaw', 'Barrier'
      "Blocky_Props_System"
    when /stone$/, /Basalt/, /Deepslate/, /Block$/, /Packed/, /Ice/, /Snow/, /^Smooth/, 'Netherrack', /Copper/, 'MushroomBlockInside'
      "Blocky_Props_StonyB"
    when /Concrete/
      "Blocky_Props_Concrete"
    when /Terracotta/
      "Blocky_Props_Terracotta"
    when /Dropper/, /Dispenser/, /Observer/, /Piston/, /Rail(On)?$/, /^Rail/, /Redstone.*Torch/, /RedstoneDust/, /Comparator/, /Repeater/
      "Blocky_Props_Redstone"
    when /furnace/i, 'Loom', 'Stonecutter', 'Smoker', 'SmokerOn', /Table$/
      "Blocky_Props_Craft"
    else
      "Blocky_Props_Misc"
    end
  end

  def list_dirs fname
    Dir[fname.split("_").first + "_*.png"].map{ |fn| File.basename(fn, ".png").split("_").last }.join(", ")
  end

  def add_def x
    @lines << x.indent(2)
  end

  def add_designator designator
    @designators[designator] += 1 if designator
  end

  def add_def_from_texture fname, parentName: nil, name: nil, texPath: nil
    name ||= File.basename(fname).split(/[_.]/).first
    return if @was[name]

    @was[name] = true

    parentName ||= fname["_"] ? "Blocky_Props_Base_Multi" : "Blocky_Props_Base"
    defName = "Blocky_Props_" + name.tr("0123456789", "ABCDEFGHIJ")
    label = name.underscore.humanize.downcase

    texPath ||= File.join(File.dirname(fname), name)
    texPath.sub!(/^Textures\//, "")

    designator = name2designator(name)
    add_designator(designator)

    printf "[.] %-27s  %-12s %s\n", name, designator, fname["_"] ? list_dirs(fname) : ""

    add_def <<~EOF
      <ThingDef ParentName="#{parentName}">
        <defName>#{defName}</defName>
        <label>#{label}</label>
        <graphicData>
          <texPath>#{texPath}</texPath>
        </graphicData>
        <designatorDropdown>#{designator}</designatorDropdown>
      </ThingDef>
    EOF
  end
end

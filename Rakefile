require 'rimtool/rake_tasks'
load './lib/tasks/import.rake'

task :map2release do
  defs = []
  z = 98
  loop do
    z -= 1
    puts "[.] z=#{z}"
    tree = Nori.new.parse(
      RimTool::YADA.request("Map.GetThingList", from: "(0,0,#{z})", to: "(99,0,#{z})")
    )
    items = tree.dig('Response', 'saveable')
    break if items.nil? || items.empty?

    items = [items] if items.is_a?(Hash)
    items.each do |s|
      defName = s['def']
      next unless defName =~ /^Blocky_Props_/
      defs << defName.to_s
    end
  end
  defs.uniq!
  puts "[=] #{defs.size} defs"
  File.write "released.yml", defs.sort.to_yaml
end

task :spawn do
  defs = YAML::load_file("released.yml").delete_if{ |x| x['Door'] }.shuffle * 2
  w = 14
  h = 8
  w.times do |x|
    h.times do |z|
      RimTool::YADA.request(
        "Map.Spawn",
        at: "(#{99-2-x},0,#{99-2-z})",
        defName: defs.pop
      )
    end
  end
end

desc "render"
task :render, :model do |_, args|
  require_relative 'lib/model'
  require_relative 'lib/model_renderer'

  key = args.model
  key = "block/#{key}" unless key['block/']
  m = Model.find(key)

  r = ModelRenderer.new(m)
  Side.each_nsew do |side|
    img = r.render(side)
    img.save(fname="#{side}.png")
    puts "[=] #{fname}"
  end
end

namespace :render do
  desc "render all sides"
  task :sides, :model do |_, args|
    require_relative 'lib/model'
    require_relative 'lib/model_renderer'

    key = args.model
    key = "block/#{key}" unless key['block/']
    m = Model.find(key)

    Side.each do |side|
      img = m.render_side(side).scaled(4)
      img.save(fname="#{side}.png")
      puts "[=] #{fname}"
    end
  end
end


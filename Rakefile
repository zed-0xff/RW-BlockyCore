require 'rimtool/rake_tasks'
load './lib/tasks/import.rake'

task :map2release do
  tree = Nori.new.parse(
    RimTool::YADA.request("Map.Request_GetThingList", from: "(0,0,99)", to: "(99,0,95)")
  )
  defs = []
  tree.dig('Response', 'saveable').each do |s|
    defName = s['def']
    next unless defName =~ /^Blocky_Props_/
    defs << defName.to_s
  end
  File.write "released.yml", defs.sort.to_yaml
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


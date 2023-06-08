desc "render"
task :render, :model do |_, args|
  require_relative '../model'
  require_relative '../model_renderer'

  key = args.model
  key = "block/#{key}" unless key['block/']
  m = Model.find(key)
  m.detect_render_type unless m.render_types

  m.render_types.each do |suffix, rtype|
    r = ModelRenderer.new(m, suffix)
    Side.each_nsew do |side|
      img = r.render(side)
      img.save(fname="#{suffix}_#{side.to_s}.png")
      puts "[=] #{fname}"
    end
  end
end

namespace :render do
  desc "render all sides"
  task :sides, :model do |_, args|
    require_relative '../model'
    require_relative '../model_renderer'

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


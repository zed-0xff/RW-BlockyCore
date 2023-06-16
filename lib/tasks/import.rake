require 'digest/md5'
require 'set'

def dedup_dir! dirname
  h = Hash.new{ |k,v| k[v] = [] }
  entity_files = Hash.new{ |k,v| k[v] = [] }
  deletable_files = Set.new

  Dir[File.join(dirname, "*.png")].each do |fname|
    md5 = Digest::MD5.file(fname).hexdigest
    h[md5] << fname
    entity_name = fname.split(/[._]/).first
    entity_files[entity_name] << fname
  end
  h.each do |md5, fnames|
    next if fnames.size < 2
    #printf "[.] %2d  %s\n", fnames.size, md5
    deletable_files += fnames.sort_by(&:size)[1..-1].to_set
  end
  entity_files.each do |entity_name, fnames|
    if fnames.all?{ |fn| deletable_files.include?(fn) }
      puts "[*] deleting #{entity_name} .."
      fnames.each do |fn|
        File.unlink(fn)
      end
    end
  end
end

desc "import all"
task :import => "import:all"

namespace :import do
  task :all => [:prune, :models, :doors, :dedup, :defs]

  task :models => [:blocks, :items]

  desc "clear all imported data"
  task :prune do
    system "rm -rf Textures/Blocky/Alpha"
    system "rm -rf Defs/Alpha*"
  end

  desc "delete duplicate entities"
  task :dedup do
    Dir["Textures/Blocky/Alpha/?"].sort.each do |dirname|
      dedup_dir! dirname
    end
  end

  desc "import some models"
  task :model, :mask do |_, args|
    require_relative "../model_parser"
    a = args.mask.split("/")
    ModelParser.new(a[0], debug: true).process! a[1]
  end

  desc "import blocks"
  task :blocks do
    require_relative "../model_parser"
    ModelParser.new('block').process!
  end

  desc "import items"
  task :items do
    require_relative "../model_parser"
    #ModelParser.new('item').process!
  end

  desc "import doors"
  task :doors do
    require_relative "../door_maker"
    DoorMaker.new.process!
  end

  desc "make defs"
  task :defs do
    require_relative "../def_maker"
    DefMaker.new.process!
  end
end

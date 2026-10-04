Dir.glob(Rails.root.join('lib/monkey_patch/**/*.rb')).sort.each{|f| require f}

Dir.glob(File.expand_path('merritt/*.rb', __dir__)).sort.each(&method(:require))

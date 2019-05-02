Dir.glob(File.expand_path('tind/*.rb', __dir__)).sort.each(&method(:require))

require_relative "lib/good_audible_story_sync/version"

Gem::Specification.new do |s|
  s.name          = "good_audible_story_sync"
  s.version       = GoodAudibleStorySync::VERSION
  s.summary       = "Command-line tool to sync your read books from Audible to Storygraph and, eventually, Goodreads."
  s.description   = "Interactive script to mark books as finished as well as set the finish date on Storygraph, based on your Audible activity."
  s.authors       = ["Sarah Vessels"]
  s.email         = "cheshire137@gmail.com"
  s.files         = Dir['lib/**/*'] + %w[LICENSE README.md]
  s.bindir        = "bin"
  s.require_paths = ["lib"]
  s.executables   = ["good-audible-story-sync"]
  s.homepage      = "https://github.com/cheshire137/good-audible-story-sync"
  s.license       = "MIT"
end

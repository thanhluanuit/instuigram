raise "Refusing to seed sample posts in production" if Rails.env.production?

posts = [
  { email: "alice@instuigram.com", topic: "Ruby", color: "#CC342D", description: "Finally got Zeitwerk autoloading to behave after untangling a stray require. Small wins today. #Ruby #RubyOnRails #WebDev" },
  { email: "alice@instuigram.com", topic: "N+1", color: "#822727", description: "Six hours deep in an N+1 query and it turns out I just forgot `includes`. Every single time. #Rails #ActiveRecord #Performance" },
  { email: "bob@instuigram.com", topic: "Open Source", color: "#2F855A", description: "Pushed my first PR to an open source gem today. Nervous and excited in equal measure. #OpenSource #Ruby #100DaysOfCode" },
  { email: "bob@instuigram.com", topic: "Docker", color: "#1D63ED", description: "Docker Compose finally spins up Elasticsearch without eating all my RAM. Small victories. #Docker #Elasticsearch #DevOps" },
  { email: "carla@instuigram.com", topic: "TDD", color: "#6B46C1", description: "Wrote the test first, watched it fail, then made it pass. TDD really does change how you think about a problem. #TDD #Testing #CleanCode" },
  { email: "carla@instuigram.com", topic: "Refactoring", color: "#B7791F", description: "Refactored a 300-line controller action down to three methods and a service object. Feels so much lighter. #Refactoring #SOLID #Rails" },
  { email: "david@instuigram.com", topic: "Debugging", color: "#1A202C", description: "Debugging a race condition at 1am is not my favorite hobby, but here we are. #Debugging #Concurrency #SoftwareEngineering" },
  { email: "david@instuigram.com", topic: "PostgreSQL", color: "#336791", description: "Added a covering index and watched a 4-second query drop to 12ms. Postgres never stops surprising me. #PostgreSQL #Database #Performance" },
  { email: "elena@instuigram.com", topic: "Pair Programming", color: "#C05621", description: "Pair programming session turned into a two-hour whiteboard talk on cache invalidation. Worth every minute. #PairProgramming #Caching #Rails" },
  { email: "elena@instuigram.com", topic: "Sidekiq", color: "#B91C1C", description: "Sidekiq quietly processing thousands of background jobs while I sip my coffee. Async is beautiful. #Sidekiq #BackgroundJobs #Ruby" },
  { email: "farid@instuigram.com", topic: "Code Review", color: "#2C7A7B", description: "Code review comment of the day: 'this works, but can you explain why?' Best kind of feedback. #CodeReview #SoftwareEngineering #Mentorship" },
  { email: "farid@instuigram.com", topic: "Elasticsearch", color: "#005571", description: "Migrated our search from a hand-rolled SQL LIKE query to Elasticsearch. Fuzzy matching for the win. #Elasticsearch #SearchEngine #Rails" },
  { email: "grace@instuigram.com", topic: "Git", color: "#F05033", description: "Interactive git rebase finally clicked for me today. My commit history has never looked cleaner. #Git #VersionControl #DevLife" },
  { email: "grace@instuigram.com", topic: "CI/CD", color: "#2D3748", description: "Shipped behind a feature flag today instead of a long-lived branch. Trunk-based development is growing on me. #CI #ContinuousDelivery #DevOps" },
  { email: "hiro@instuigram.com", topic: "ActiveSupport", color: "#742A2A", description: "Spent the morning reading the Rails source for ActiveSupport::Concern. Framework code is the best documentation. #Rails #Ruby #LearningInPublic" },
  { email: "hiro@instuigram.com", topic: "Hotwire", color: "#553C9A", description: "First time writing a Stimulus controller and it just worked. Hotwire keeps surprising me with how little JS I actually need. #Hotwire #Stimulus #Turbo" },
  { email: "ines@instuigram.com", topic: "Security", color: "#9B2C2C", description: "Brakeman flagged a mass assignment issue before it ever reached production. Static analysis earns its keep. #Security #Brakeman #Rails" },
  { email: "ines@instuigram.com", topic: "API Design", color: "#276749", description: "Load tested the API today — 500 req/s and Puma barely broke a sweat. #Performance #API #Ruby" },
  { email: "jack@instuigram.com", topic: "Algorithms", color: "#975A16", description: "Explained Big O notation to a junior dev using pizza slices. Whatever gets the concept across. #Algorithms #Mentorship #ComputerScience" },
  { email: "jack@instuigram.com", topic: "Gemfile", color: "#C53030", description: "Merged my first contribution to a gem I use every single day. Full circle moment. #OpenSource #Gemfile #Ruby" }
].freeze

missing_emails = posts.map { |attrs| attrs[:email] }.uniq - User.where(email: posts.map { |attrs| attrs[:email] }.uniq).pluck(:email)
raise "Missing seed users: #{missing_emails.join(', ')} — run `bin/rails db:seed:users` first" if missing_emails.any?

FONT_CANDIDATES = [
  "/Library/Fonts/Arial Unicode.ttf",
  "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
  "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
  "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
].freeze
SEED_POST_FONT = FONT_CANDIDATES.find { |path| File.exist?(path) }

def build_seed_post_image(topic, color)
  path = Rails.root.join("tmp", "seed_post_#{topic.parameterize}.png")
  MiniMagick::Tool::Magick.new do |convert|
    convert.size("800x800")
    convert << "xc:#{color}"
    convert.gravity("center")
    convert.pointsize(48)
    convert.fill("white")
    convert.font(SEED_POST_FONT) if SEED_POST_FONT
    convert.annotate("+0+0", topic)
    convert << path.to_s
  end
  path
end

post_created_count = 0
posts.each do |attrs|
  user = User.find_by!(email: attrs[:email])
  post = Post.find_or_create_by!(description: attrs[:description], user: user) do |new_post|
    image_path = build_seed_post_image(attrs[:topic], attrs[:color])
    new_post.image.attach(
      io: File.open(image_path),
      filename: "#{attrs[:topic].parameterize}.png",
      content_type: "image/png"
    )
    File.delete(image_path)
  end
  post_created_count += 1 if post.previously_new_record?
end

puts "Seeded #{Post.count} posts."
puts "#{post_created_count} new post(s) created this run." if post_created_count.positive?

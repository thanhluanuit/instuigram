raise "Refusing to seed sample users in production" if Rails.env.production?

users = [
  { email: "alice@instuigram.com", username: "alice", name: "Alice Johnson", website: "https://alicejohnson.com", bio: "Coffee, code, and cameras.", phone: 5550101, gender: "female" },
  { email: "bob@instuigram.com", username: "bob.travels", name: "Bob Martinez", website: "https://bobtravels.com", bio: "Exploring one city at a time.", phone: 5550102, gender: "male" },
  { email: "carla@instuigram.com", username: "carla_art", name: "Carla Rossi", website: "https://carlarossi.art", bio: "Digital painter and illustrator.", phone: 5550103, gender: "female" },
  { email: "david@instuigram.com", username: "david.codes", name: "David Kim", website: "https://davidkim.dev", bio: "Building things on the internet.", phone: 5550104, gender: "male" },
  { email: "elena@instuigram.com", username: "elena_runs", name: "Elena Petrova", website: "https://elenapetrova.run", bio: "Marathoner. Always training.", phone: 5550105, gender: "female" },
  { email: "farid@instuigram.com", username: "farid.eats", name: "Farid Haidari", website: "https://faridhaidari.blog", bio: "Home cook sharing weekend recipes.", phone: 5550106, gender: "male" },
  { email: "grace@instuigram.com", username: "grace.reads", name: "Grace Thompson", website: "https://gracethompson.blog", bio: "Books, tea, and rainy days.", phone: 5550107, gender: "female" },
  { email: "hiro@instuigram.com", username: "hiro.shoots", name: "Hiro Tanaka", website: "https://hirotanaka.photo", bio: "Street photography from Tokyo.", phone: 5550108, gender: "male" },
  { email: "ines@instuigram.com", username: "ines.garden", name: "Ines Costa", website: "https://inescosta.garden", bio: "Growing something new every season.", phone: 5550109, gender: "female" },
  { email: "jack@instuigram.com", username: "jack.builds", name: "Jack Sullivan", website: "https://jacksullivan.build", bio: "Woodworking and small home projects.", phone: 5550110, gender: "male" }
].freeze

SEED_PASSWORD = SecureRandom.alphanumeric(20)
created_count = 0
users.each do |attrs|
  user          = User.find_or_create_by!(email: attrs[:email]) do |new_user|
    new_user.assign_attributes(attrs.except(:email))
    new_user.password              = SEED_PASSWORD
    new_user.password_confirmation = SEED_PASSWORD
  end
  created_count += 1 if user.previously_new_record?
end

puts "Seeded #{User.count} users."
puts "#{created_count} new account(s) created this run — password: #{SEED_PASSWORD}" if created_count.positive?

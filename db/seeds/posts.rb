raise "Refusing to seed sample posts in production" if Rails.env.production?

posts = [
  { email: "alice@instuigram.com", image: "chris-weiher-xlAfCD2vOxQ-unsplash.jpg", description: "Lost in my own little jungle today. #GardenLife #TropicalVibes #PlantsOfInstagram" },
  { email: "alice@instuigram.com", image: "pexels-buusecolak-29544877.jpg", description: "Coffee, a sweet treat, and nowhere to be. #CoffeeTime #TurkishCoffee #CafeVibes" },
  { email: "alice@instuigram.com", image: "pexels-buusecolak-32188278.jpg", description: "Iced coffee, a good book, and golden hour light. #IcedCoffee #BookAndCoffee #CafeLife" },
  { email: "bob@instuigram.com", image: "pexels-buusecolak-32994444.jpg", description: "Fueling the grind, one heart-shaped latte at a time. #LatteArt #CoffeeBreak #WorkFromHome" },
  { email: "bob@instuigram.com", image: "pexels-divinetechygirl-1181472.jpg", description: "Two heads are always better than one. #TeamWork #OfficeLife #Collaboration" },
  { email: "bob@instuigram.com", image: "pexels-duc-nguyen-2149183346-33411901.jpg", description: "Chasing the mist through endless green terraces. #RiceTerraces #Vietnam #NatureLovers" },
  { email: "carla@instuigram.com", image: "pexels-duc-nguyen-2149183346-38510810.jpg", description: "Golden hour over the valley never gets old. #Sunset #Travel #LandscapePhotography" },
  { email: "carla@instuigram.com", image: "pexels-ivan-s-8117814.jpg", description: "Behind the scenes with my favorite people. #BehindTheScenes #FriendsForever #ContentCreator" },
  { email: "carla@instuigram.com", image: "pexels-ivan-s-8117815.jpg", description: "Lights, camera, action with the crew. #ContentCreation #BTS #Squad" },
  { email: "david@instuigram.com", image: "pexels-jonathanborba-13450786.jpg", description: "Heads down and locked into the workday. #OfficeLife #WorkMode #Productivity" },
  { email: "david@instuigram.com", image: "pexels-julio-lopez-75309646-34258667.jpg", description: "Late night in the zone, three screens deep and no signs of stopping. #Coding #Programmer #TechLife" },
  { email: "david@instuigram.com", image: "pexels-karola-g-7876664.jpg", description: "Breaking down the numbers one chart at a time. #Business #Teamwork #OfficeLife" },
  { email: "elena@instuigram.com", image: "pexels-mikhail-nilov-7988749.jpg", description: "Walking the team through this one line by line. #Coding #TechLife #Teamwork" },
  { email: "elena@instuigram.com", image: "pexels-mizunokozuki-12902873.jpg", description: "Another productive day with the team. #StartupLife #OfficeLife #Teamwork" },
  { email: "elena@instuigram.com", image: "pexels-pornsiri-thetchutithamgull-1272073-33317312.jpg", description: "Lost in the lantern-lined streets of Hoi An. #HoiAn #Travel #Vietnam" },
  { email: "farid@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-14022164.jpg", description: "Old town mornings, flowers and flags everywhere you look. #HoiAn #StreetPhotography #Vietnam" },
  { email: "farid@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-14022215.jpg", description: "Balancing baskets of marigolds through the old town. #HoiAn #Travel #StreetPhotography" },
  { email: "farid@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-14776912.jpg", description: "Chasing valley views that stop you in your tracks. #Vietnam #Nature #Landscape" },
  { email: "grace@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-2153635.jpg", description: "Golden hour hitting different in these mountains. #Sunset #Vietnam #Nature" },
  { email: "grace@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-2162471.jpg", description: "Da Nang's dragon lighting up the night sky. #DaNang #Sunset #Vietnam" },
  { email: "grace@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-30750566.jpg", description: "Banana delivery day — this road smells amazing right now. #Vietnam #StreetPhotography #RuralLife" },
  { email: "hiro@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-6128998.jpg", description: "Chasing golden hour over these terraces and it did not disappoint. #Travel #Nature #RiceTerraces" },
  { email: "hiro@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-6711284.jpg", description: "Wandering Hoi An's old streets with all these lanterns overhead. #HoiAn #Travel #StreetPhotography" },
  { email: "hiro@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-6711298.jpg", description: "Just me, a straw hat, and a street full of lanterns. #HoiAn #Vietnam #Travel" },
  { email: "ines@instuigram.com", image: "pexels-ron-lach-8367762.jpg", description: "Beer pong chaos, fully documented for the group chat. #FriendsHangout #GameNight #GoodTimes" },
  { email: "ines@instuigram.com", image: "pexels-silverkblack-39190465.jpg", description: "Deep in the charts tonight — the market never sleeps. #Finance #StockMarket #Tech" },
  { email: "ines@instuigram.com", image: "pexels-thales13-38808473.jpg", description: "City lights hitting different tonight. #CityLights #NightPhotography #Skyline" },
  { email: "jack@instuigram.com", image: "pexels-tuongchopper-32445526.jpg", description: "That skyline glow never gets old. #Cityscape #NightPhotography #Vietnam" },
  { email: "jack@instuigram.com", image: "pexels-tuongchopper-32445533.jpg", description: "Standing by the river, soaking in the skyline. #CityLights #Skyline #NightPhotography" },
  { email: "jack@instuigram.com", image: "pexels-zayed-hossain-52728970-36706825.jpg", description: "Late night grind with the team, getting things shipped. #Startup #TeamWork #CodingLife" }
].freeze

missing_emails = posts.map { |attrs| attrs[:email] }.uniq - User.where(email: posts.map { |attrs| attrs[:email] }.uniq).pluck(:email)
raise "Missing seed users: #{missing_emails.join(', ')} — run `bin/rails db:seed:users` first" if missing_emails.any?

post_created_count = 0
posts.each do |attrs|
  user = User.find_by!(email: attrs[:email])
  post = Post.find_or_create_by!(description: attrs[:description], user: user) do |new_post|
    image_path = Rails.root.join("db/seeds/images", attrs[:image])
    new_post.image.attach(
      io: File.open(image_path),
      filename: attrs[:image],
      content_type: "image/jpeg"
    )
  end
  post_created_count += 1 if post.previously_new_record?
end

puts "Seeded #{Post.count} posts."
puts "#{post_created_count} new post(s) created this run." if post_created_count.positive?

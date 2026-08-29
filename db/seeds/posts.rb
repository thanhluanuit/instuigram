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
  { email: "jack@instuigram.com", image: "pexels-zayed-hossain-52728970-36706825.jpg", description: "Late night grind with the team, getting things shipped. #Startup #TeamWork #CodingLife" },
  { email: "elena@instuigram.com", image: "pexels-alin-serban-1867310-32798746.jpg", description: "Forest loop before the heat kicked in. #TrailRunning #MorningRun #RunnersOfInstagram" },
  { email: "elena@instuigram.com", image: "pexels-vanngo-ng-105653827-33874842.jpg", description: "Ridge line all to myself this morning. #TrailRunning #MountainRunning #Endurance" },
  { email: "elena@instuigram.com", image: "pexels-katya-wolf-8729008.jpg", description: "Hurdling logs and calling it training. #TrailRunning #ForestRun #RunHappy" },
  { email: "farid@instuigram.com", image: "pexels-tuan-vy-903011268-36243530.jpg", description: "Best banh mi on the block, no contest. #StreetFood #Vietnam #FoodStall" },
  { email: "farid@instuigram.com", image: "pexels-hujason-29714906.jpg", description: "Queued twenty minutes and would do it again. #StreetFood #NightMarket #FoodieFinds" },
  { email: "farid@instuigram.com", image: "pexels-hoffman11-28074076.jpg", description: "Market aunties know exactly what you need. #StreetFood #SeoulEats #MarketLife" },
  { email: "jack@instuigram.com", image: "pexels-shkrabaanthony-4706105.jpg", description: "Centering clay is ninety percent patience. #Pottery #Handmade #StudioLife" },
  { email: "jack@instuigram.com", image: "pexels-koolshooters-9736289.jpg", description: "Wheel running, radio on, phone in another room. #Pottery #Ceramics #SlowMaking" },
  { email: "jack@instuigram.com", image: "pexels-cottonbro-6693557.jpg", description: "Muddy hands, quiet afternoon. #Pottery #Handmade #MakersGonnaMake" },
  { email: "hiro@instuigram.com", image: "pexels-hatice-baran-153179658-16586906.jpg", description: "Caught the light just right on this one. #StreetStyle #StreetPhotography #OOTD" },
  { email: "hiro@instuigram.com", image: "pexels-bymuratisikofficial-24553838.jpg", description: "She walked past like the pavement owed her rent. #StreetStyle #Fashion #CityLife" },
  { email: "hiro@instuigram.com", image: "pexels-emris-17086258.jpg", description: "Murals and menswear, my favourite combination. #StreetStyle #StreetPhotography #Fashion" },
  { email: "bob@instuigram.com", image: "pexels-rifkyilhamrd-788213.jpg", description: "Six of us, one very optimistic trail map. #Hiking #Mountains #WeekendAdventure" },
  { email: "bob@instuigram.com", image: "pexels-anastassiya-golovko-77755601-8659357.jpg", description: "Cloud level reached, legs fully cooked. #Hiking #Mountains #Trekking" },
  { email: "bob@instuigram.com", image: "pexels-karolina-2031292-9629654.jpg", description: "Fog rolled in and swallowed the whole ridge. #Hiking #Fog #Mountains" },
  { email: "carla@instuigram.com", image: "pexels-volkerthimm-34133564.jpg", description: "Nothing but clean lines and blue sky. #Architecture #Minimalism #DesignDetails" },
  { email: "carla@instuigram.com", image: "pexels-rick98-3467152.jpg", description: "Looked up and found a composition. #Architecture #Geometry #LookUp" },
  { email: "carla@instuigram.com", image: "pexels-thomas-balabaud-735585-30093555.jpg", description: "Studying shapes for the next piece. #Architecture #Minimalism #Inspiration" },
  { email: "alice@instuigram.com", image: "pexels-picswithjer-30215324.jpg", description: "Front row and my ears are still ringing. #LiveMusic #Concert #GigPhotography" },
  { email: "alice@instuigram.com", image: "pexels-nolandlive-26447525.jpg", description: "Everyone in this room knew every word. #LiveMusic #Concert #NightOut" },
  { email: "alice@instuigram.com", image: "pexels-fotios-photos-13230484.jpg", description: "Lighting rig did half the work tonight. #LiveMusic #Concert #StageLights" },
  { email: "grace@instuigram.com", image: "pexels-marc-winter-2647960-4222628.jpg", description: "Walked the whole beach and lost track of time. #BeachSunset #Ocean #GoldenHour" },
  { email: "grace@instuigram.com", image: "pexels-hugo-silva-1095125615-28402681.jpg", description: "Stood here until the light went. #BeachSunset #Ocean #SlowLiving" },
  { email: "grace@instuigram.com", image: "pexels-killian-eon-1185568-9574073.jpg", description: "Boards down, sun going, perfect end. #BeachSunset #Surf #GoldenHour" },
  { email: "david@instuigram.com", image: "pexels-wal-172619-2156618639-36192733.jpg", description: "Long shadows on the morning walk. #DogsOfInstagram #BlackAndWhite #CityWalk" },
  { email: "david@instuigram.com", image: "pexels-beyzaa-yurtkuran-279977530-16180680.jpg", description: "First snow and they lost their minds. #DogsOfInstagram #GoldenRetriever #WinterWalk" },
  { email: "david@instuigram.com", image: "pexels-nathanael-mosqueda-19935333-6520908.jpg", description: "Cold bridge, warm company. #DogsOfInstagram #WinterWalk #DogWalk" },
  { email: "ines@instuigram.com", image: "pexels-david-levinson-331488832-14397066.jpg", description: "Low tide, two very sandy dogs. #DogsOfInstagram #BeachDay #Ocean" },
  { email: "ines@instuigram.com", image: "pexels-rachel-claire-4577835.jpg", description: "Watched the last surfers head in. #BeachSunset #Surf #Ocean" },
  { email: "ines@instuigram.com", image: "pexels-danu-j-301811465-16204518.jpg", description: "Night market glow is a whole mood. #StreetFood #NightMarket #MarketLife" },
  { email: "farid@instuigram.com", image: "pexels-iltertaha-38959004.jpg", description: "Found my new Saturday morning ritual. #Bakery #ArtisanBread #FreshlyBaked" },
  { email: "farid@instuigram.com", image: "pexels-wal-172619-2156618639-35993723.jpg", description: "Every shelf smells better than the last. #Bakery #SourdoughClub #BreadLover" },
  { email: "farid@instuigram.com", image: "pexels-chris-f-38966-10481790.jpg", description: "Watching the oven do its thing. #Bakery #BakingDay #ArtisanBread" },
  { email: "farid@instuigram.com", image: "pexels-daniel-dan-47825192-7543099.jpg", description: "Still warm, barely made it home. #FreshlyBaked #BreadLover #WeekendBaking" },
  { email: "bob@instuigram.com", image: "pexels-mlkbnl-20434997.jpg", description: "Amsterdam does mornings properly. #CityCycling #Amsterdam #BikeLife" },
  { email: "bob@instuigram.com", image: "pexels-airamdphoto-18635975.jpg", description: "Everyone here is on two wheels and I love it. #CityCycling #Amsterdam #BikeLife" },
  { email: "bob@instuigram.com", image: "pexels-joaquin-carfagna-3131171-17627576.jpg", description: "Valencia sunshine, nowhere to be. #CityCycling #Valencia #SlowTravel" },
  { email: "bob@instuigram.com", image: "pexels-sen-sen-48863532-9568024.jpg", description: "Two baskets waiting on somebody's errands. #BikeLife #StreetPhotography #QuietStreets" },
  { email: "elena@instuigram.com", image: "pexels-tima-miroshnichenko-5928334.jpg", description: "Beach flow before the world wakes up. #Yoga #SunriseYoga #Mindfulness" },
  { email: "elena@instuigram.com", image: "pexels-jordicosta-32658879.jpg", description: "Warrior two under the palms. #Yoga #BeachYoga #GoldenHour" },
  { email: "elena@instuigram.com", image: "pexels-aysegul-aytoren-46790226-16111007.jpg", description: "Stretching out the miles from yesterday. #Yoga #Recovery #SunriseYoga" },
  { email: "grace@instuigram.com", image: "pexels-kseniachernaya-3952079.jpg", description: "Two hours gone and I have regrets about none of it. #Bookshop #Reading #BookLover" },
  { email: "grace@instuigram.com", image: "pexels-celine-3776818-16177510.jpg", description: "Paris pavement bookshops are dangerous for my wallet. #Bookshop #Paris #BookLover" },
  { email: "grace@instuigram.com", image: "pexels-kristina-bekher-1944658582-36150701.jpg", description: "Paperback stacks in Bath and no plan to leave. #Bookshop #Reading #Bath" },
  { email: "grace@instuigram.com", image: "pexels-furkanfdemir-6309864.jpg", description: "Reading standing up because the chair was too far. #Bookshop #Reading #BookLover" },
  { email: "elena@instuigram.com", image: "pexels-metekaan-34633066.jpg", description: "Same loop, completely different park this month. #Autumn #FallColors #ParkRun" },
  { email: "hiro@instuigram.com", image: "pexels-fotios-photos-5616665.jpg", description: "Walked this path just for the colour. #Autumn #FallColors #StreetPhotography" },
  { email: "david@instuigram.com", image: "pexels-rahmi-aksoz-53797721-18594962.jpg", description: "Nobody has sat here in weeks. #Autumn #FallColors #QuietMoments" },
  { email: "carla@instuigram.com", image: "pexels-kampus-6760866.jpg", description: "Long table, longer evening. #DinnerParty #FriendsGathering #GoodFood" },
  { email: "carla@instuigram.com", image: "pexels-askar-abayev-5638815.jpg", description: "String lights make everything taste better. #DinnerParty #SummerEvenings #FriendsGathering" },
  { email: "carla@instuigram.com", image: "pexels-julia-m-cameron-8841431.jpg", description: "To absolutely nothing in particular. #DinnerParty #Cheers #FriendsGathering" },
  { email: "carla@instuigram.com", image: "pexels-cottonbro-4878006.jpg", description: "Rooftop, snacks, no phones. Mostly. #RooftopDinner #FriendsGathering #GoodTimes" },
  { email: "hiro@instuigram.com", image: "pexels-daniel-543223.jpg", description: "Four hours of this out the window. #TrainTravel #SlowTravel #WindowSeat" },
  { email: "hiro@instuigram.com", image: "pexels-quang-nguyen-vinh-222549-2132496.jpg", description: "She had the better camera angle the whole trip. #TrainTravel #WindowSeat #Travel" },
  { email: "hiro@instuigram.com", image: "pexels-dharamveer-12217338.jpg", description: "Red train, right on time. #TrainTravel #StreetPhotography #Railway" },
  { email: "ines@instuigram.com", image: "pexels-sema-nur-949285251-31641383.jpg", description: "Could not walk past this stall. #FlowerMarket #Florist #Blooms" },
  { email: "ines@instuigram.com", image: "pexels-mlkbnl-27910545.jpg", description: "Zurich market and every bucket a different colour. #FlowerMarket #Florist #Blooms" },
  { email: "ines@instuigram.com", image: "pexels-ilayda0700-31497181.jpg", description: "Tulip season is officially open. #FlowerMarket #Tulips #Blooms" },
  { email: "ines@instuigram.com", image: "pexels-saliha-nur-sogutlu-1892471882-37037939.jpg", description: "Bought three, wanted thirty. #FlowerMarket #Florist #Blooms" },
  { email: "jack@instuigram.com", image: "pexels-brett-sayles-2006010.jpg", description: "Landed it on the ninth try. #Skateboarding #SkatePark #StreetCulture" },
  { email: "jack@instuigram.com", image: "pexels-cottonbro-5037667.jpg", description: "Ramp is covered in paint and so are we. #Skateboarding #SkatePark #StreetCulture" },
  { email: "jack@instuigram.com", image: "pexels-davincidelasfotos-32435746.jpg", description: "Sunny afternoon, empty park, perfect. #Skateboarding #SkatePark #GoodTimes" },
  { email: "jack@instuigram.com", image: "pexels-sebastian-casimiro-242488940-13185433.jpg", description: "Street spots always hit harder. #Skateboarding #StreetCulture #StreetPhotography" },
  { email: "alice@instuigram.com", image: "pexels-th2city-14737154.jpg", description: "Rain turned the whole street into a mirror. #NeonNights #RainyNight #NightPhotography" },
  { email: "alice@instuigram.com", image: "pexels-novillolapeyra-12608643.jpg", description: "Walked home the long way for this one. #NeonNights #RainyNight #NightPhotography" },
  { email: "alice@instuigram.com", image: "pexels-matreding-11285597.jpg", description: "Shot through a wet window and kept it. #NeonNights #Blur #NightPhotography" },
  { email: "alice@instuigram.com", image: "pexels-leyla21m-30744872.jpg", description: "Baku cobblestones after the rain. #NeonNights #RainyNight #StreetPhotography" },
  { email: "david@instuigram.com", image: "pexels-jonas-horsch-102497290-29951931.jpg", description: "Signal is terrible and that is the point. #WinterCabin #Snow #OffGrid" },
  { email: "david@instuigram.com", image: "pexels-nikolaeva-nastia-3312562-10754168.jpg", description: "Snowed in with a full coffee jar. #WinterCabin #Snow #CozySeason" },
  { email: "david@instuigram.com", image: "pexels-handespics-37194767.jpg", description: "Whole forest went quiet overnight. #WinterCabin #Snow #WinterForest" }
].freeze

missing_emails = posts.map { |attrs| attrs[:email] }.uniq - User.where(email: posts.map { |attrs| attrs[:email] }.uniq).pluck(:email)
raise "Missing seed users: #{missing_emails.join(', ')} — run `bin/rails db:seed:users` first" if missing_emails.any?

rng           = Random.new(20_260_829)
newest_post   = 3.hours.ago
timeline_span = 150.days
waking_hours  = 7..22

queues  = posts.group_by { |attrs| attrs[:email] }.values.map(&:dup)
ordered = []
until queues.all?(&:empty?)
  pass = queues.reject(&:empty?).shuffle(random: rng)
  pass.push(pass.shift) if ordered.any? && pass.size > 1 && pass.first.first[:email] == ordered.last[:email]
  pass.each { |queue| ordered << queue.shift }
end

gaps      = Array.new(ordered.size) { rng.rand(0.15..1.0) }
scale     = timeline_span / gaps.sum
running   = newest_post - timeline_span
timeline  = gaps.map { |gap| running += gap * scale }
                .map { |at| waking_hours.cover?(at.hour) ? at : at.change(hour: rng.rand(waking_hours), min: rng.rand(60)) }
                .sort

post_created_count = 0
post_retimed_count = 0
ordered.each_with_index do |attrs, index|
  user       = User.find_by!(email: attrs[:email])
  created_at = timeline[index]

  post = Post.find_or_create_by!(description: attrs[:description], user: user) do |new_post|
    image_path = Rails.root.join("db/seeds/images", attrs[:image])
    new_post.image.attach(
      io: File.open(image_path),
      filename: attrs[:image],
      content_type: "image/jpeg"
    )
    new_post.created_at = created_at
    new_post.updated_at = created_at
  end
  post_created_count += 1 if post.previously_new_record?

  next if (post.created_at - created_at).abs < 1.day

  post.update_columns(created_at: created_at, updated_at: created_at)
  post_retimed_count += 1
end

puts "Seeded #{Post.count} posts."
puts "#{post_created_count} new post(s) created this run." if post_created_count.positive?
puts "#{post_retimed_count} existing post(s) retimed onto the seed timeline." if post_retimed_count.positive?
puts "Timeline spans #{Post.minimum(:created_at).to_date} to #{Post.maximum(:created_at).to_date}."

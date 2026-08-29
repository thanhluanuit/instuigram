raise "Refusing to seed sample users in production" if Rails.env.production?

users = [
  { email: "alice@instuigram.com", username: "alice", name: "Alice Johnson", website: "https://alicejohnson.com", bio: "Coffee, code, and cameras.", phone: 5550101, gender: "female", avatar: "pexels-amirho3intavkooli-15846842.jpg" },
  { email: "bob@instuigram.com", username: "bob.travels", name: "Bob Martinez", website: "https://bobtravels.com", bio: "Exploring one city at a time.", phone: 5550102, gender: "male", avatar: "pexels-arya-bajra-283675810-15801008.jpg" },
  { email: "carla@instuigram.com", username: "carla_art", name: "Carla Rossi", website: "https://carlarossi.art", bio: "Digital painter and illustrator.", phone: 5550103, gender: "female", avatar: "pexels-baris-yigit-239931604-13800992.jpg" },
  { email: "david@instuigram.com", username: "david.codes", name: "David Kim", website: "https://davidkim.dev", bio: "Building things on the internet.", phone: 5550104, gender: "male", avatar: "pexels-buyfnb-1168401-2227817.jpg" },
  { email: "elena@instuigram.com", username: "elena_runs", name: "Elena Petrova", website: "https://elenapetrova.run", bio: "Marathoner. Always training.", phone: 5550105, gender: "female", avatar: "pexels-deniz-caglusu-2162799059-38486436.jpg" },
  { email: "farid@instuigram.com", username: "farid.eats", name: "Farid Haidari", website: "https://faridhaidari.blog", bio: "Home cook sharing weekend recipes.", phone: 5550106, gender: "male", avatar: "pexels-fritz-jaspers-746891536-18704327.jpg" },
  { email: "grace@instuigram.com", username: "grace.reads", name: "Grace Thompson", website: "https://gracethompson.blog", bio: "Books, tea, and rainy days.", phone: 5550107, gender: "female", avatar: "pexels-honggyu-kim-582278127-17407385.jpg" },
  { email: "hiro@instuigram.com", username: "hiro.shoots", name: "Hiro Tanaka", website: "https://hirotanaka.photo", bio: "Street photography from Tokyo.", phone: 5550108, gender: "male", avatar: "pexels-jean-francois-frenel-2157629552-35070219.jpg" },
  { email: "ines@instuigram.com", username: "ines.garden", name: "Ines Costa", website: "https://inescosta.garden", bio: "Growing something new every season.", phone: 5550109, gender: "female", avatar: "pexels-joolsmagools-28731658.jpg" },
  { email: "jack@instuigram.com", username: "jack.builds", name: "Jack Sullivan", website: "https://jacksullivan.build", bio: "Woodworking and small home projects.", phone: 5550110, gender: "male", avatar: "pexels-koprivakart-6638266.jpg" },
  { email: "kai@instuigram.com", username: "kai.surfs", name: "Kai Nakamura", website: "https://kainakamura.surf", bio: "Dawn patrol, most days.", phone: 5550111, gender: "male", avatar: "pexels-amorie-sam-468180864-30692444.jpg" },
  { email: "lena@instuigram.com", username: "lena.bakes", name: "Lena Fischer", website: "https://lenafischer.bakery", bio: "Sourdough and slow mornings.", phone: 5550112, gender: "female", avatar: "pexels-ana-dala-3075106-5861277.jpg" },
  { email: "mateo@instuigram.com", username: "mateo.rides", name: "Mateo Alvarez", website: "https://mateoalvarez.cc", bio: "Two wheels, no plan.", phone: 5550113, gender: "male", avatar: "pexels-ante-emmanuel-3691197-33585719.jpg" },
  { email: "nadia@instuigram.com", username: "nadia.writes", name: "Nadia Haddad", website: "https://nadiahaddad.ink", bio: "Drafting something long.", phone: 5550114, gender: "female", avatar: "pexels-darina-belonogova-8384894.jpg" },
  { email: "priya@instuigram.com", username: "priya.paints", name: "Priya Raman", website: "https://priyaraman.studio", bio: "Watercolour, mostly skies.", phone: 5550115, gender: "female", avatar: "pexels-felix-young-449360607-26803801.jpg" },
  { email: "rosa@instuigram.com", username: "rosa.threads", name: "Rosa Delgado", website: "https://rosadelgado.studio", bio: "Sewing my own patterns.", phone: 5550116, gender: "female", avatar: "pexels-golnar-sabzpoush-rashidi-1317651-2530364.jpg" },
  { email: "amara@instuigram.com", username: "amara.knits", name: "Amara Okafor", website: "https://amaraokafor.co", bio: "One more row, then bed.", phone: 5550117, gender: "female", avatar: "pexels-ifeyinkastudios-29852852.jpg" },
  { email: "zara@instuigram.com", username: "zara.sings", name: "Zara Mensah", website: "https://zaramensah.music", bio: "Choir on Sundays, demos on Tuesdays.", phone: 5550118, gender: "female", avatar: "pexels-ifeyinkastudios-29852895.jpg" },
  { email: "wes@instuigram.com", username: "wes.pedals", name: "Wes Carter", website: "https://wescarter.bike", bio: "Commuter turned tourer.", phone: 5550119, gender: "male", avatar: "pexels-klaus-dieter-2157247827-34884824.jpg" },
  { email: "tara@instuigram.com", username: "tara.dives", name: "Tara Lindqvist", website: "https://taralindqvist.blue", bio: "Happiest ten metres down.", phone: 5550120, gender: "female", avatar: "pexels-krivitskiy-17477621.jpg" },
  { email: "chloe@instuigram.com", username: "chloe.skates", name: "Chloe Martin", website: "https://chloemartin.skate", bio: "Still working on that kickflip.", phone: 5550121, gender: "female", avatar: "pexels-mabel-uchuypoma-615185464-31779750.jpg" },
  { email: "dmitri@instuigram.com", username: "dmitri.hikes", name: "Dmitri Volkov", website: "https://dmitrivolkov.trail", bio: "Long walks, heavy pack.", phone: 5550122, gender: "male", avatar: "pexels-mahmutyilmaz-36997584.jpg" },
  { email: "iris@instuigram.com", username: "iris.blooms", name: "Iris Lindgren", website: "https://irislindgren.garden", bio: "Cut flowers every Friday.", phone: 5550123, gender: "female", avatar: "pexels-matosuky-754634156-18715039.jpg" },
  { email: "vera@instuigram.com", username: "vera.grows", name: "Vera Novak", website: "https://veranovak.green", bio: "Allotment number fourteen.", phone: 5550124, gender: "female", avatar: "pexels-moe-magners-5330489.jpg" },
  { email: "yusuf@instuigram.com", username: "yusuf.cooks", name: "Yusuf Demir", website: "https://yusufdemir.kitchen", bio: "Feeding whoever turns up.", phone: 5550125, gender: "male", avatar: "pexels-peterjkambey-20057476.jpg" },
  { email: "quinn@instuigram.com", username: "quinn.climbs", name: "Quinn O'Brien", website: "https://quinnobrien.climb", bio: "Indoor walls, outdoor weekends.", phone: 5550126, gender: "female", avatar: "pexels-prolificpeople-30004325.jpg" },
  { email: "omar@instuigram.com", username: "omar.frames", name: "Omar Sultani", website: "https://omarsultani.photo", bio: "Film only, developed at home.", phone: 5550127, gender: "male", avatar: "pexels-santiago-sauceda-gonzalez-3426899-10173294.jpg" },
  { email: "esra@instuigram.com", username: "esra.pots", name: "Esra Yildiz", website: "https://esrayildiz.ceramics", bio: "Throwing mugs, mostly wonky.", phone: 5550128, gender: "female", avatar: "pexels-shvets-production-7545341.jpg" },
  { email: "bruno@instuigram.com", username: "bruno.plays", name: "Bruno Costa", website: "https://brunocosta.audio", bio: "Bass player for hire.", phone: 5550129, gender: "male", avatar: "pexels-simeart-31052395.jpg" },
  { email: "xiu@instuigram.com", username: "xiu.draws", name: "Xiu Chen", website: "https://xiuchen.gallery", bio: "Ink, paper, repeat.", phone: 5550130, gender: "female", avatar: "pexels-studio-urbano-922916462-31936484.jpg" },
  { email: "felipe@instuigram.com", username: "felipe.jams", name: "Felipe Rojas", website: "https://feliperojas.live", bio: "Small rooms, loud nights.", phone: 5550131, gender: "male", avatar: "pexels-toan-d-cong-680842095-22129917.jpg" },
  { email: "hugo@instuigram.com", username: "hugo.reads", name: "Hugo Almeida", website: "https://hugoalmeida.page", bio: "Secondhand bookshops, every city.", phone: 5550132, gender: "male", avatar: "pexels-vincent-santamaria-194760512-37148308.jpg" },
  { email: "tomas@instuigram.com", username: "tomas.repairs", name: "Tomas Novotny", website: "https://tomasnovotny.fix", bio: "Fixing what other people throw out.", phone: 5550133, gender: "male", avatar: "pexels-alby-14192856.jpg" },
  { email: "gareth@instuigram.com", username: "gareth.brews", name: "Gareth Pryce", website: "https://garethpryce.beer", bio: "Homebrew, mostly drinkable.", phone: 5550134, gender: "male", avatar: "pexels-centre-for-ageing-better-55954677-7858229.jpg" },
  { email: "sofia@instuigram.com", username: "sofia.films", name: "Sofia Ruiz", website: "https://sofiaruiz.film", bio: "Super 8 and a lot of patience.", phone: 5550135, gender: "female", avatar: "pexels-thefullonmonet-18406110.jpg" }
].freeze

rng            = Random.new(20_260_829)
oldest_signup  = 14.months.ago
newest_signup  = 6.months.ago
gaps           = Array.new(users.size) { rng.rand(0.15..1.0) }
scale          = (newest_signup - oldest_signup) / gaps.sum
running        = oldest_signup
signups        = gaps.map { |gap| running += gap * scale }

SEED_PASSWORD = SecureRandom.alphanumeric(20)
created_count = 0
avatar_created_count = 0
signup_dated_count = 0
users.each_with_index do |attrs, index|
  created_at = signups[index]

  user = User.find_or_create_by!(email: attrs[:email]) do |new_user|
    new_user.assign_attributes(attrs.except(:email, :avatar))
    new_user.password              = SEED_PASSWORD
    new_user.password_confirmation = SEED_PASSWORD
    new_user.created_at            = created_at
    new_user.updated_at            = created_at
  end
  created_count += 1 if user.previously_new_record?

  if (user.created_at - created_at).abs >= 1.day
    user.update_columns(created_at: created_at, updated_at: created_at)
    signup_dated_count += 1
  end

  next if user.avatar.attached?

  user.avatar.attach(
    io: File.open(Rails.root.join("db/seeds/avatars", attrs[:avatar])),
    filename: attrs[:avatar],
    content_type: "image/jpeg"
  )
  avatar_created_count += 1
end

puts "Seeded #{User.count} users."
puts "#{created_count} new account(s) created this run — password: #{SEED_PASSWORD}" if created_count.positive?
puts "#{avatar_created_count} avatar(s) attached this run." if avatar_created_count.positive?
puts "#{signup_dated_count} existing account(s) redated onto the signup timeline." if signup_dated_count.positive?

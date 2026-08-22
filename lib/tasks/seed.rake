namespace :db do
  namespace :seed do
    desc "Seed only the sample users"
    task users: :environment do
      load Rails.root.join("db/seeds/users.rb")
    end

    desc "Seed only the sample posts (requires the sample users to already exist)"
    task posts: :environment do
      load Rails.root.join("db/seeds/posts.rb")
    end
  end
end

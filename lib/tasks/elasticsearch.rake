namespace :elasticsearch do
  desc "Create the Post index in Elasticsearch if it doesn't already exist"
  task create_index: :environment do
    if Post.__elasticsearch__.index_exists?
      puts "Index #{Post.index_name} already exists"
    else
      Post.__elasticsearch__.create_index!
      puts "Created index #{Post.index_name}"
    end
  end

  desc "Recreate the Post index and reindex every post"
  task reindex: :environment do
    Post.__elasticsearch__.create_index!(force: true)
    Post.import(force: false, batch_size: 1000)
    Post.__elasticsearch__.refresh_index!
    puts "Reindexed #{Post.count} posts into #{Post.index_name}"
  end
end

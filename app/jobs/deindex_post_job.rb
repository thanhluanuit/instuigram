class DeindexPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    Elasticsearch::Model.client.delete(index: Post.index_name, id: post_id)
  rescue Elastic::Transport::Transport::Errors::NotFound
    nil
  end
end

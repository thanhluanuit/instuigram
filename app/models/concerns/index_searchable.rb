module IndexSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name do
      if Rails.env.test?
        "#{model_name.collection}_test#{ENV["ELASTICSEARCH_TEST_WORKER_NUMBER"]}"
      else
        "#{model_name.collection}_#{Rails.env}"
      end
    end

    after_commit :enqueue_indexing, on: :create
    after_commit :enqueue_deindexing, on: :destroy
  end

  private

  def enqueue_indexing
    "Index#{self.class.name}Job".constantize.perform_later(id)
  end

  def enqueue_deindexing
    "Deindex#{self.class.name}Job".constantize.perform_later(id)
  end
end

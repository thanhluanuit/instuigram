module Post::Searchable
  extend ActiveSupport::Concern

  included do
    include IndexSearchable

    mapping dynamic: false do
      indexes :id, type: "integer"
      indexes :description, type: "text"
      indexes :created_at, type: "date"
      indexes :hashtag_names, type: "text"
    end

    def self.search(query)
      return if query.blank?

      term = query.delete_prefix("#")
      __elasticsearch__.search(
        query: {
          multi_match: {
            query: term,
            fields: %w[description hashtag_names^3],
            fuzziness: "AUTO"
          }
        }
      )
    end
  end

  def as_indexed_json(_options = {})
    as_json(only: %i[id description created_at], methods: %i[hashtag_names])
  end

  def hashtag_names
    hash_tags.pluck(:name)
  end
end

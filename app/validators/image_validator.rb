class ImageValidator < ActiveModel::EachValidator
  ALLOWED_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_SIZE      = 10.megabytes

  def validate_each(record, attribute, value)
    return unless value.attached?

    unless value.content_type.in?(ALLOWED_TYPES)
      record.errors.add(attribute, "must be a PNG, JPEG, or WebP")
    end

    if value.blob.byte_size > MAX_SIZE
      record.errors.add(attribute, "must be smaller than #{MAX_SIZE / 1.megabyte}MB")
    end
  end
end

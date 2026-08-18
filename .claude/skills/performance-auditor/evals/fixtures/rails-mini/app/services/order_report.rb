class OrderReport
  # PLANT: unindexed filter — orders.user_id has no index in structure.sql.
  def self.for_user(user_id)
    Order.where(user_id: user_id).order(created_at: :desc)
  end

  # PLANT: synchronous mail in the request path.
  def self.deliver!(order)
    OrderMailer.receipt(order).deliver_now
  end

  # PLANT: whole-table iteration in one job run, unbatched writes.
  def self.recalculate_all
    Order.all.each do |order|
      order.update!(total_cents: order.line_items.sum(&:cents))
    end
  end
end

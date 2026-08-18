class ProductsController < ApplicationController
  # PLANT: N+1 — the index view touches product.category and product.reviews
  # with no eager loading. High-traffic listing path.
  def index
    @products = Product.where(status: "active").order(created_at: :desc).limit(25)
  end

  def show
    @product = Product.find(params[:id])
    # PLANT: synchronous external HTTP in the request path.
    @rates = Net::HTTP.get(URI("https://rates.example.com/v1/latest"))
  end
end

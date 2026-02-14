Rails.application.routes.draw do
  mount RailsCurdBase::Engine => "/rails_curd_base"

  # API 路由
  namespace :api do
    resources :posts
  end
end


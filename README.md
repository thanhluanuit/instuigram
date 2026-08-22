## Build Instagram by Ruby on Rails
[![CI](https://github.com/thanhluanuit/instuigram/actions/workflows/ci.yml/badge.svg)](https://github.com/thanhluanuit/instuigram/actions/workflows/ci.yml)

I’ll guide you step by step learning Ruby on Rails through building the Instagram application.


## What’ll you learn after complete this project?
- How to start a new Rails application?
- Design System from Craft
- Understanding MVC (Model — View — Controller) architecture
- Model: Active Record migration, validation, callback, association, and query interface
- View: Layout, Partial and Form helpers
- Controller: Actions, Strong Parameters
- Rails Routing
- Active Storage to upload files
- Using Bootstrap, Devise, Kaminari gem in Rails application

## Tech Stacks
- Back-end:
    - Ruby 3.3.11
    - Rails 8.1.3.1
    - Database: PostgreSQL
    - Cache / sessions: Redis (`redis_cache_store`)
    - Background jobs: Sidekiq
    - Search: Elasticsearch 8.x (`elasticsearch-model` + `elasticsearch-rails`), run locally via `docker compose up -d`
    - Gems: Devise, Kaminari, Active Storage
- Front-end:
    - HTML, CSS, Javascript, Turbo + Stimulus (via importmap-rails)
    - Bootstrap 4.6.x
    - SCSS via Sprockets

## Table of Contents:
- Part 1: [medium.com/luanotes/build-instagram-by-ruby-on-rails-part-1](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-1-fef7837ee399)
- Part 2: [medium.com/luanotes/build-instagram-by-ruby-on-rails-part-2](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-2-d70b44f5c7e6)
- Part 3: [medium.com/luanotes/build-instagram-by-ruby-on-rails-part-3](https://medium.com/luanotes/build-instagram-by-ruby-on-rails-part-3-2cb65dca46d7)

## Main functions:

### Homepage
![Home page](app/assets/images/home_page.png "Homepage")

### User Profile Page
![User Profile Page](app/assets/images/user_profile.png "User Profile Page")

### Edit User Page
![Edit User Page](app/assets/images/edit_user_profile.png "Edit User Page")

### Search Page
![Search Page](app/assets/images/search_page.png "Search Page")

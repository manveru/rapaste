class CssController < Ramaze::Controller
  map '/css'
  provide :css, :engine => :Sass
  trait :sass_options => {
    :style => :compressed,
  }
end

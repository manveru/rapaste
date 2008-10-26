class CssController < Ramaze::Controller
  engine :Sass
  trait :sass_options => {
    :style => :compressed,
  }
end

Ramaze::Route[%r!/css/(.+)\.css!] = '/css/%s'

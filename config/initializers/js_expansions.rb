ActionView::Helpers::AssetTagHelper.register_javascript_expansion({
  :jquery => [
    "jquery.js",
    "jquery.ui.js"
  ],
  :rails => [
    "rails.js",
    "application.js",

  ],
  :less => "http://lesscss.googlecode.com/files/less-1.0.18.min.js"
})
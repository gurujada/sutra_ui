# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix_live_view],
  plugins: [Phoenix.LiveView.HTMLFormatter]
]

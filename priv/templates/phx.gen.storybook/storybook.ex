defmodule <%= inspect schema.module %>.Storybook do
  use PhxLiveStorybook,
    otp_app: <%= inspect schema.app %>,
    content_path: Path.expand("../../storybook", __DIR__),
    # assets path are remote path, not local file-system paths
    css_path: "/assets/css/storybook.css",
    js_path: "/assets/js/storybook.js"
end

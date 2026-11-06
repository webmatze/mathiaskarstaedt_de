module Github
  # Anything that went wrong talking to GitHub, so callers catch one class and
  # the admin can show the message next to the project.
  class Error < StandardError; end
end

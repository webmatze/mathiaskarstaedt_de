# Everything a visitor can see without signing in.
class PublicController < ApplicationController
  allow_unauthenticated_access
end

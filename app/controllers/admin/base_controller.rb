class Admin::BaseController < ApplicationController
  layout "admin"

  # Authentication is on by default (see the Authentication concern), so there is
  # nothing to switch on here — this class exists to keep the admin layout and
  # any future admin-wide concerns in one place.
end

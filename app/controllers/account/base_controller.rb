class Account::BaseController < ApplicationController
  allow_unauthenticated_access
  include CustomerAuthentication
  layout "store"
end

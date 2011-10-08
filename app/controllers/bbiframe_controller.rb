class BbiframeController < ApplicationController
  layout false
  def index
    @newurl = request.protocol + request.host + ":3000"
  end
end

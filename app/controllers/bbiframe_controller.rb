class BbiframeController < ApplicationController
  def index
    @newurl = request.protocol + request.host + ":3000"
  end
end

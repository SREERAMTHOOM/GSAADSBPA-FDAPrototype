require "rest-client"
class EnforcementsController < ApplicationController
  def retrieve
    @from = params[:From]
    @to = params[:To]
    @limit = params[:Limit]
    request="https://api.fda.gov/device/event.json?search=date_received:[20130101+TO+20141231]&limit=" + @limit.to_s
    request="https://api.fda.gov/food/enforcement.json?search=report_date:[" + @from + "+TO+" + @to + "]&limit=" + @limit
    Rails.logger.debug request
    @restresponse = RestClient.get request
    @rubyObj = JSON.parse(@restresponse)
    #puts @restresponse
  end
  def index
    @from = '20130101'
    @to = '20131231'
    @limit = '3'
  end
end

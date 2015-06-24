require "rest-client"
$rubyObj
$advEvents
$enfEvents
class EnforcementsController < ApplicationController
  def index
    $advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?limit=5")['results']
    $enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?limit=5")['results']
  end
  def retrieve
    @from = params[:From]
    @to = params[:To]
    @limit = params[:Limit]
    @requestUrl="https://api.fda.gov/food/enforcement.json?search=report_date:[" + @from + "+TO+" + @to + "]&limit=" + @limit
    Rails.logger.debug @requestUrl
    @restresponse = RestClient.get @requestUrl
    $rubyObj = JSON.parse(@restresponse)
    #puts @restresponse
  end
  def index1
    @from = '20130101'
    @to = '20131231'
    @limit = '3'
    @chartData = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?search=date_received:[20140101+TO+20140115]+AND+device.generic_name:x-ray&count=date_received")['results']
    @results = "{"
    @chartData.each do |result|
      @results +=  "\"#{result['time']}\": #{result['count']},"
    end
    @results += "}"
  end
  def display
    @eventId = params[:eventId]
    @eventObj = $rubyObj['results'][@eventId.to_i]
  end
  def devicereport
    type = params[:type]
    if type == "device"
	url = "https://api.fda.gov/device/event.json?count=date_received"
    elsif type == "enf"
	url = "https://api.fda.gov/device/enforcement.json?count=report_date"
    end
    all = JSON.parse(RestClient.get url)['results']
    result = "{"
    all.group_by{ |h| h['time'][0..3] }.each do |loc,events|
      puts "'#{loc}': "
      print "--> "
      #puts events.map{ |e| e['count']}.join(', ')
      count = 0
      events.map{ |e| e['count']}.each do |cnt|
         count += cnt.to_i
      end
      puts "for " + loc + " count is : " + count.to_s
      result += "\"#{loc}\": #{count},"
    end
    result = result[0...-1]
    result += "}"
    puts result
    render json: JSON.parse(result)
  end
  def report1
    chartData = RestClient.get "https://api.fda.gov/device/event.json?search=date_received:[20140101+TO+20140115]+AND+device.generic_name:x-ray&count=date_received"
    chartData = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?search=date_received:[20140101+TO+20141115]+AND+device.generic_name:x-ray&count=date_received")['results']
    data1 = '{
  "results": 
    {
      "2014-01-02": 56,
      "2014-01-03": 23,
      "2014-01-04": 45,
      "2014-01-05": 15,
      "2014-01-06": 73,
      "2014-01-07": 64,
      "2014-01-08": 64,
      "2014-01-09": 84,
      "2014-01-12": 12,
      "2014-01-13": 32,
      "2014-01-14": 56
    }
  
}';
    data = '{"2013-02-10": 11, "2013-02-11": 6}';
    results = "{"
    chartData.each do |result|
      results +=  "\"#{result['time']}\": #{result['count']},"
    end
    results = results[0...-1]
    results += "}"

    render json: JSON.parse(results)
    #render json: JSON.parse(data1)['results']
  end
end

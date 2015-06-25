require "rest-client"

class EnforcementsController < ApplicationController
  def index
    @advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?limit=5")['results']
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?limit=5")['results']
  end
  def devicereport
    type = params[:type]
    if type == "device"
	  url = "https://api.fda.gov/device/event.json?count=date_received"
    elsif type == "enf"
	  url = "https://api.fda.gov/device/enforcement.json?count=report_date"
	else
	  url = "https://api.fda.gov/device/enforcement.json?count=report_date"
    end
    all = JSON.parse(RestClient.get url)['results']
    result = "{"
    all.group_by{ |h| h['time'][0..3] }.each do |loc,events|
      #puts "'#{loc}': "
      #print "--> "
      #puts events.map{ |e| e['count']}.join(', ')
      count = 0
      events.map{ |e| e['count']}.each do |cnt|
         count += cnt.to_i
      end
      #puts "for " + loc + " count is : " + count.to_s
      result += "\"#{loc}\": #{count},"
    end
    result = result[0...-1]
    result += "}"
    puts result
    render json: JSON.parse(result)
  end
  def devices
	@tempData=[ 
		{name: "Series A", data: [["Football", 11], ["Basketball", 5]]},
		{name: "Series B", data: [["Football", 10], ["Basketball", 8]]} 
		]
	@tempData << {name: "Series C", data: [["Football", 13], ["Basketball", 15]]}
	@tempData << {name: "Series C1", data: [["Football", 13], ["Basketball", 15]]}
	@tempData << {name: "Series C2", data: [["Football", 13], ["Basketball", 15]]}
	@tempData << {name: "Series C3", data: [["Football", 13], ["Basketball", 15]]}
  end
  def details
    @advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?limit=20")['results']
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?limit=20")['results']
  end
  def enfreports
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?limit=20")['results']
  end
end

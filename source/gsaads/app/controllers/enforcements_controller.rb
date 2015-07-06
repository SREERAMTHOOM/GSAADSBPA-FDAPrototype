require "rest-client"

class EnforcementsController < ApplicationController
  def get_content url
	puts url
	#puts "Escaped url : #{url.gsub(' ','+')}"
	begin
	  response = RestClient.get URI.escape(url.gsub(' ', '+'))
	  #puts "after getting response"
	  #puts response
	  return JSON.parse(response)['results']
	rescue => e
	  #puts "in rescue : #{e}"
	  #return e.response["error"]["message"]
	  return nil
	end
  end
  def index
	@advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?search=_exists_:event_type+AND+_exists_:date_of_event+AND+_exists_:manufacturer_name+AND+_exists_:device.generic_name+AND+date_of_event:[20150101+TO+20151231]&limit=100")['results']
	@advEvents = @advEvents.sort_by { |k| k["date_of_event"] }.reverse
	@enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?search=_exists_:recalling_firm+AND+_exists_:recall_initiation_date+AND+_exists_:status+AND+_exists_:classification+AND+recall_initiation_date:[20150101+TO+20151231]&limit=100")['results']
	@enfEvents = @enfEvents.sort_by { |k| k["recall_initiation_date"] }.reverse
  end
  def reportgroupbyyear
	type = params[:type]
	if type == "device"
	  url = "https://api.fda.gov/device/event.json?search=date_received:[20000101+TO+20151231]&count=date_received"
	elsif type == "enf"
	  url = "https://api.fda.gov/device/enforcement.json?count=report_date"
	else
	  url = "https://api.fda.gov/device/enforcement.json?count=report_date"
	end
	all = get_content(url)
	if all.nil? || all.empty?
		render json: JSON.parse("{\"NoDataFound\": 1}")
	else
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
		#puts result
		render json: JSON.parse(result)
	end
  end
  def reports
	#puts "came here"
	type = params[:type]
	@startYear = params[:startYear]
	@mfr = params[:mfr]
	@deviceType = params[:deviceType]
	#puts @startYear
	@startYear = "2015" if @startYear.nil? || @startYear.empty?
	@mfr = "ABBOTT LABORATORIES" if @mfr.nil? || @mfr.empty?
	@deviceType = "" if @deviceType.nil? || @deviceType.empty?
	if type == "advbymfr"
	  url = "https://api.fda.gov/device/event.json?search=manufacturer_name:" + @mfr + "+AND+_exists_:date_of_event+AND+date_received:[" + @startYear + "0101+TO+" + @startYear + "1231]&count=device.generic_name.exact"
	elsif type == "advbytype"
		url = "https://api.fda.gov/device/event.json?search=device.generic_name:" + @deviceType + "+AND+manufacturer_name:" + @mfr + "+AND+_exists_:date_of_event+AND+date_of_event:[" + @startYear + "0101+TO+" + @startYear + "1231]&count=event_type.exact"
	elsif type == "enfbymfr"
		url = "https://api.fda.gov/device/enforcement.json?search=report_date:[20150101+TO+20151231]&limit=25&count=recalling_firm.exact"
	else
	  url = "https://api.fda.gov/device/enforcement.json?count=report_date"
	end
	all = get_content(url)
	if all.nil? || all.empty?
		render json: JSON.parse("{\"NoDataFound\": 1}")
	else
		#puts "Response in reports: #{all}"
		result = "{"
		all.take(25).each do |item|
		  result += "\"#{item["term"].titleize.gsub(/"/, '\\"')}\": #{item["count"]},"
		end
		result = result[0...-1]
		result += "}"
		render json: JSON.parse(result)
	end
  end
  def devices
	@startYear = params[:startYear]
	@endYear = params[:endYear]
	@deviceType = params[:deviceType]
	@startYear = "2000" if @startYear.nil? || @startYear.empty?
	@endYear = "2015" if @endYear.nil? || @endYear.empty?
	@deviceType = "AC+POWERED+HOSPITAL+BED" if @deviceType.nil? || @deviceType.empty?
	eventsUrl = "https://api.fda.gov/device/event.json?search=generic_name:" + @deviceType + "+AND+date_received:[" + @startYear + "0101+TO+" + @endYear + "1231]&count=date_received"
	enfUrl = "https://api.fda.gov/device/enforcement.json?search=reason_for_recall:" + @deviceType + "+AND+recall_initiation_date:[" + @startYear + "0101+TO+" + @endYear + "1231]&count=recall_initiation_date"
	eventData = get_content(eventsUrl)
	#puts "eventData: #{eventData}"
	enfData = get_content(enfUrl)
	#puts "enfData: #{enfData}"
	@tempData = []
	#puts "tempData: #{@tempData}"
	if eventData.nil? || eventData.empty? || enfData.nil? || enfData.empty?
		#puts "tempData1: #{@tempData}"
		@tempData << ['', 'No Data Found', 'No Data Found']
		@tempData << ['No Data Found', 0, 0]
	else
		eventDataHash = {}
		eventData.group_by{ |h| h['time'][0..3] }.each do |loc,events|
			count = 0
			events.map{ |e| e['count']}.each do |cnt|
				count += cnt.to_i
			end
			#puts "loc: #{loc}"
			eventDataHash[loc] = count
		end
		enfDataHash = {}
		enfData.group_by{ |h| h['time'][0..3] }.each do |loc,events|
			count = 0
			events.map{ |e| e['count']}.each do |cnt|
				count += cnt.to_i
			end
			#puts "loc: #{loc}"
			enfDataHash[loc] = count
		end
		allKeys = eventDataHash.keys + enfDataHash.keys
		allKeys = allKeys.uniq.sort
		#puts "eventDataHash: #{eventDataHash}"
		#puts "enfDataHash: #{enfDataHash}"
		@tempData << ['', 'Adverse Events', 'Enforcements']
		allKeys.each { |a| 
			@tempData << [a, (eventDataHash[a].nil? ? 0 : eventDataHash[a]), (enfDataHash[a].nil? ? 0 : enfDataHash[a])]
		}
		#puts "tempData4: #{@tempData}"
	end
  end
  def adveventsdetails
	@advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?search=_exists_:event_type+AND+_exists_:date_of_event+AND+_exists_:manufacturer_name+AND+_exists_:device.generic_name+AND+date_of_event:[20150101+TO+20151231]&limit=100")['results']
	@advEvents = @advEvents.sort_by { |k| k["date_of_event"] }.reverse
  end
  def enfdetails
	@enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?search=_exists_:recalling_firm+AND+_exists_:recall_initiation_date+AND+_exists_:status+AND+_exists_:classification+AND+recall_initiation_date:[20150101+TO+20151231]&limit=100")['results']
	@enfEvents = @enfEvents.sort_by { |k| k["recall_initiation_date"] }.reverse
  end
  def enfreports
	@enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?search=report_date:[20150101+TO+20151231]&limit=25&count=recalling_firm.exact")['results']
  end
  def advevents
	  @startYear = params[:startYear]
	  @mfr = params[:mfr]
	  @startYear = "2000" if @startYear.nil? || @startYear.empty?
	  @mfr = "ABBOTT LABORATORIES" if @mfr.nil? || @mfr.empty?
	  @deviceType = "AC+POWERED+HOSPITAL+BED" if @deviceType.nil? || @deviceType.empty?
	  #url = "https://api.fda.gov/device/event.json?search=date_received:[" + @startYear + "0101+TO+" + @startYear + "0101]&count=manufacturer_name"
	  #@advByMfr = JSON.parse(RestClient.get url)['results']
	  #puts "URL : " + url
  end
end

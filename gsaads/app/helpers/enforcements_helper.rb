module EnforcementsHelper
	def format_description(data, len)
		if(data.length>len)
			data[0...len] + "..."
		else
			data
		end
	end

	def format_datestr(datestr)
		date = datestr.to_s.to_date
		date_arr = date.to_s.split('-')
		date_arr[1].to_s+"."+date_arr[2].to_s+"."+date_arr[0].to_s
	end

	def current_class?(test_path)
		''
	end
end

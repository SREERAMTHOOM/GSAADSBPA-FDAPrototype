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
	end
end

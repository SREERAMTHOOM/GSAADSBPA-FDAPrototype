module EnforcementsHelper
	def format_description(data, len)
		if(data.length>len)
			data[0...len] + "..."
		else
			data
		end
	end

	def format_datestr(datestr)
		if datestr.nil? || datestr.empty?
			return ''
		end
		date = datestr.to_s.to_date
		date_arr = date.to_s.split('-')
		date_arr[1].to_s+"."+date_arr[2].to_s+"."+date_arr[0].to_s
	end

	def nav_link(link_text, link_path)
		trimmedValue = link_path.split("?")[0]
		class_name = current_page?(trimmedValue) ? 'active' : ''
		content_tag(:li, :class => class_name) do
			link_to link_text, link_path
		end
	end
end

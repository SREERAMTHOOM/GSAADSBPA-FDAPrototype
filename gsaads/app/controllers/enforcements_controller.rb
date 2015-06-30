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
	@deviceType = "INFUSION PUMP" if @deviceType.nil? || @deviceType.empty?
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
	  @deviceType = "INFUSION PUMP" if @deviceType.nil? || @deviceType.empty?
	  #url = "https://api.fda.gov/device/event.json?search=date_received:[" + @startYear + "0101+TO+" + @startYear + "0101]&count=manufacturer_name"
	  #@advByMfr = JSON.parse(RestClient.get url)['results']
	  #puts "URL : " + url
  end
  $yearList = [['2000', 2000], ['2001', 2001], ['2002', 2002], ['2003', 2003], ['2004', 2004], ['2005', 2005], ['2006', 2006], ['2007', 2007], ['2008', 2008], ['2009', 2009], ['2010', 2010], ['2011', 2011], ['2012', 2012], ['2013', 2013], ['2014', 2014], ['2015', 2015]]
  $mfrList = [
['Abbott Diabetes Care Inc, Usa', 'ABBOTT+DIABETES+CARE+INC+USA'],
['Abbott Laboratories', 'ABBOTT+LABORATORIES'],
['Advanced Sterilization Products', 'Advanced+Sterilization+Products'],
['Alcon - Irvine Technology Center', 'ALCON+-+IRVINE+TECHNOLOGY+CENTER'],
['Alere San Diego, Inc.', 'Alere+San+Diego+Inc.'],
['American Medical Systems, Inc.', 'AMERICAN+MEDICAL+SYSTEMS+INC.'],
['Animas Corporation', 'ANIMAS+CORPORATION'],
['Arrow International Inc', 'Arrow+International+Inc'],
['Atrium Medical Corporation', 'Atrium+Medical+Corporation'],
['Av-Temecula-Ct', 'AV-TEMECULA-CT'],
['Bausch & Lomb', 'BAUSCH+&+LOMB'],
['Baxter Healthcare', 'BAXTER+HEALTHCARE'],
['Baxter Healthcare - Irvine', 'BAXTER+HEALTHCARE+-+IRVINE'],
['Baxter Healthcare - Largo', 'BAXTER+HEALTHCARE+-+LARGO'],
['Baxter Healthcare - Mountain Home', 'BAXTER+HEALTHCARE+-+MOUNTAIN+HOME'],
['Baxter Healthcare - Singapore', 'BAXTER+HEALTHCARE+-+SINGAPORE'],
['Baxter Healthcare Corp', 'BAXTER+HEALTHCARE+CORP'],
['Baxter Healthcare Corp.', 'Baxter+Healthcare+Corp.'],
['Baxter Healthcare Corporation', 'BAXTER+HEALTHCARE+CORPORATION'],
['Baxter Healthcare Pte. Ltd.', 'BAXTER+HEALTHCARE+PTE.+LTD.'],
['Beckman Coulter', 'BECKMAN+COULTER'],
['Beckman Coulter Inc.', 'Beckman+Coulter+Inc.'],
['Beckman Coulter, Inc.', 'BECKMAN+COULTER+INC.'],
['Becton Dickinson & Co.', 'Becton+Dickinson+&+Co.'],
['Becton Dickinson & Company', 'Becton+Dickinson+&+Company'],
['Biomerieux Inc', 'Biomerieux+Inc'],
['Biomet 3I, Llc', 'Biomet+3i+LLC'],
['Biomet Microfixation, Llc', 'Biomet+Microfixation+LLC'],
['Biomet Orthopedics', 'BIOMET+ORTHOPEDICS'],
['Biomet, Inc.', 'Biomet+Inc.'],
['Biotronik Se & Co. Kg', 'BIOTRONIK+SE+&+CO.+KG'],
['Boston Scientific', 'BOSTON+SCIENTIFIC'],
['Boston Scientific - Galway', 'BOSTON+SCIENTIFIC+-+GALWAY'],
['Boston Scientific - Maple Grove', 'BOSTON+SCIENTIFIC+-+MAPLE+GROVE'],
['Boston Scientific - Marlborough', 'BOSTON+SCIENTIFIC+-+MARLBOROUGH'],
['Boston Scientific Corporation', 'Boston+Scientific+Corporation'],
['Boston Scientific Neuromodulation', 'BOSTON+SCIENTIFIC+NEUROMODULATION'],
['Cardiac Pacemakers', 'CARDIAC+PACEMAKERS'],
['Cardiac Pacemakers, Inc', 'CARDIAC+PACEMAKERS+INC'],
['Carefusion 303, Inc.', 'CareFusion+303+Inc.'],
['Carestream Health Inc.', 'Carestream+Health+Inc.'],
['Carestream Health, Inc.', 'Carestream+Health+Inc.'],
['Churchill Medical Systems, Inc.', 'Churchill+Medical+Systems+Inc.'],
['Cochlear Ltd.', 'COCHLEAR+LTD.'],
['Codman & Shurtleff, Inc.', 'Codman+&+Shurtleff+Inc.'],
['Conmed Corporation', 'ConMed+Corporation'],
['Cordis Corporation', 'Cordis+Corporation'],
['Cordis De Mexico', 'CORDIS+DE+MEXICO'],
['Covidien', 'COVIDIEN'],
['Covidien Llc', 'Covidien+LLC'],
['Covidien Lp', 'Covidien+LP'],
['Cpi - Del Caribe', 'CPI+-+DEL+CARIBE'],
['Custom Medical Specialties, Inc.', 'Custom+Medical+Specialties+Inc.'],
['Customed, Inc', 'Customed+Inc'],
['Cyberonics, Inc.', 'CYBERONICS+INC.'],
['Datascope Corp.', 'DATASCOPE+CORP.'],
['Davol, Inc., Subs. C. R. Bard, Inc.', 'Davol+Inc.+Subs.+C.+R.+Bard+Inc.'],
['Depuy International', 'DEPUY+INTERNATIONAL'],
['Depuy International, Ltd.', 'DEPUY+INTERNATIONAL+LTD.'],
['Depuy Mitek, Inc., A Johnson & Johnson Co.', 'DePuy+Mitek+Inc.+a+Johnson+&+Johnson+Co.'],
['Depuy Orthopaedics, Inc.', 'DePuy+Orthopaedics+Inc.'],
['Depuy Spine, Inc.', 'DePuy+Spine+Inc.'],
['Depuy Synthes Power Tools', 'DEPUY+SYNTHES+POWER+TOOLS'],
['Depuy Warsaw', 'DEPUY+WARSAW'],
['Deroyal Industries Inc', 'DeRoyal+Industries+Inc'],
['Dexcom, Inc.', 'DEXCOM+INC.'],
['Edwards Lifesciences', 'EDWARDS+LIFESCIENCES'],
['Edwards Lifesciences, Llc', 'Edwards+Lifesciences+LLC'],
['Elekta, Inc.', 'Elekta+Inc.'],
['Ethicon Endo-Surgery, Inc.', 'ETHICON+ENDO-SURGERY+INC.'],
['Ethicon Endo-Surgery, Inc. (Cincinnati)', 'ETHICON+ENDO-SURGERY+INC.+(CINCINNATI)'],
['Ethicon Endo-Surgery, Llc', 'ETHICON+ENDO-SURGERY+LLC'],
['Ethicon Endo-Surgery, Llc.', 'ETHICON+ENDO-SURGERY+LLC.'],
['Ethicon Inc.', 'ETHICON+INC.'],
['Ethicon, Inc.', 'ETHICON+INC.'],
['Exactech, Inc.', 'Exactech+Inc.'],
['Fresenius Medical Care Holdings, Inc.', 'Fresenius+Medical+Care+Holdings+Inc.'],
['Fresenius Medical Care North America', 'FRESENIUS+MEDICAL+CARE+NORTH+AMERICA'],
['Gambro Renal Products, Incorporated', 'Gambro+Renal+Products+Incorporated'],
['Ge Healthcare', 'GE+Healthcare'],
['Ge Healthcare, Llc', 'GE+Healthcare+LLC'],
['Ge Oec Medical Systems (Slc)', 'GE+OEC+MEDICAL+SYSTEMS+(SLC)'],
['Ge Oec Medical Systems Inc.', 'GE+OEC+MEDICAL+SYSTEMS+INC.'],
['Ge Oec Medical Systems, Inc', 'GE+OEC+Medical+Systems+Inc'],
['Genzyme Corporation, A Sanofi Company', 'Genzyme+Corporation+A+Sanofi+Company'],
['Guidant Crm Clonmel Ireland', 'GUIDANT+CRM+CLONMEL+IRELAND'],
['Hill-Rom Ritter', 'HILL-ROM+RITTER'],
['Hill-Rom, Inc.', 'HILL-ROM+INC.'],
['Hospira Costa Rica Ltd.', 'HOSPIRA+COSTA+RICA+LTD.'],
['Hospira Inc.', 'Hospira+Inc.'],
['Icu Medical, Inc.', 'ICU+Medical+Inc.'],
['Instrumed International, Inc.', 'Instrumed+International+Inc.'],
['Instrumentation Laboratory Co.', 'Instrumentation+Laboratory+Co.'],
['Integra Lifesciences Corp.', 'Integra+LifeSciences+Corp.'],
['Integra Lifesciences Corporation', 'Integra+LifeSciences+Corporation'],
['Intuitive Surgical, Inc.', 'Intuitive+Surgical+Inc.'],
['Intuitive Surgical,Inc.', 'INTUITIVE+SURGICALINC.'],
['Invacare Corporation', 'Invacare+Corporation'],
['Invacare Florida Operations', 'INVACARE+FLORIDA+OPERATIONS'],
['Invacare Taylor Street', 'INVACARE+TAYLOR+STREET'],
['Karl Storz Endoscopy America Inc', 'Karl+Storz+Endoscopy+America+Inc'],
['King Systems Corp.', 'King+Systems+Corp.'],
['Lemaitre Vascular, Inc.', 'LeMaitre+Vascular+Inc.'],
['Lifescan Europe, A Division Of Cilag Gmbh Intl', 'LIFESCAN+EUROPE+A+DIVISION+OF+CILAG+GMBH+INTL'],
['Lifescan Inc.', 'LIFESCAN+INC.'],
['Lifescan, Inc.', 'LIFESCAN+INC.'],
['Linvatec Corp. Dba Conmed Linvatec', 'Linvatec+Corp.+dba+ConMed+Linvatec'],
['Lumiquick Diagnostics Inc.', 'LumiQuick+Diagnostics+Inc.'],
['Mdt Puerto Rico Operations Co', 'MDT+PUERTO+RICO+OPERATIONS+CO'],
['Mdt Puerto Rico Operations Co., Juncos', 'MDT+PUERTO+RICO+OPERATIONS+CO.+JUNCOS'],
['Medtronic Inc. Cardiac Rhythm Disease Management', 'Medtronic+Inc.+Cardiac+Rhythm+Disease+Management'],
['Medtronic Ireland', 'MEDTRONIC+IRELAND'],
['Medtronic Med Rel Medtronic Puerto Rico', 'MEDTRONIC+MED+REL+MEDTRONIC+PUERTO+RICO'],
['Medtronic Med Rel, Inc.', 'MEDTRONIC+MED+REL+INC.'],
['Medtronic Minimed', 'MEDTRONIC+MINIMED'],
['Medtronic Navigation, Inc.', 'Medtronic+Navigation+Inc.'],
['Medtronic Neuromodulation', 'Medtronic+Neuromodulation'],
['Medtronic Puerto Rico Operations Co.', 'MEDTRONIC+PUERTO+RICO+OPERATIONS+CO.'],
['Medtronic Puerto Rico Operations Med-Rel', 'MEDTRONIC+PUERTO+RICO+OPERATIONS+MED-REL'],
['Medtronic Puerto Rico, Inc.', 'MEDTRONIC+PUERTO+RICO+INC.'],
['Medtronic S.A.', 'MEDTRONIC+S.A.'],
['Medtronic Sofamor Danek Usa Inc', 'Medtronic+Sofamor+Danek+USA+Inc'],
['Medtronic Sofamor Danek Usa, Inc', 'MEDTRONIC+SOFAMOR+DANEK+USA+INC'],
['Medtronic, Inc.', 'MEDTRONIC+INC.'],
['Microtek Medical Inc', 'Microtek+Medical+Inc'],
['Mpri', 'MPRI'],
['Navilyst Medical, Inc', 'Navilyst+Medical+Inc'],
['Nobel Biocare Usa Llc', 'Nobel+Biocare+Usa+Llc'],
['Nuvasive Inc', 'NuVasive+Inc'],
['Ortho-Clinical Diagnostics', 'Ortho-Clinical+Diagnostics'],
['Orthovita, Inc., Dba Stryker Orthobiologics.', 'Orthovita+Inc.+dBA+Stryker+Orthobiologics.'],
['Philips Healthcare Inc.', 'Philips+Healthcare+Inc.'],
['Philips Medical Systems', 'PHILIPS+MEDICAL+SYSTEMS'],
['Philips Medical Systems (Cleveland) Inc', 'Philips+Medical+Systems+(Cleveland)+Inc'],
['Philips Medical Systems, Inc.', 'Philips+Medical+Systems+Inc.'],
['Progressive Medical Inc', 'Progressive+Medical+Inc'],
['Remel Inc', 'Remel+Inc'],
['Roche Diagnostics', 'ROCHE+DIAGNOSTICS'],
['Roche Diagnostics Operations, Inc.', 'Roche+Diagnostics+Operations+Inc.'],
['Roche Molecular Systems, Inc.', 'Roche+Molecular+Systems+Inc.'],
['Siemens Healthcare Diagnostics', 'Siemens+Healthcare+Diagnostics'],
['Siemens Healthcare Diagnostics Inc', 'Siemens+Healthcare+Diagnostics+Inc'],
['Siemens Healthcare Diagnostics, Inc', 'Siemens+Healthcare+Diagnostics+Inc'],
['Siemens Healthcare Diagnostics, Inc.', 'Siemens+Healthcare+Diagnostics+Inc.'],
['Siemens Medical Solutions Usa,  Inc', 'Siemens+Medical+Solutions+USA++Inc'],
['Siemens Medical Solutions Usa, Inc', 'Siemens+Medical+Solutions+USA+Inc'],
['Siemens Medical Solutions Usa, Inc.', 'Siemens+Medical+Solutions+USA+Inc.'],
['Smith & Nephew Inc', 'Smith+&+Nephew+Inc'],
['Smith & Nephew, Inc. Endoscopy Division', 'Smith+&+Nephew+Inc.+Endoscopy+Division'],
['Smiths Medical Asd, Inc.', 'Smiths+Medical+ASD+Inc.'],
['Spinal Elements, Inc', 'Spinal+Elements+Inc'],
['Spinefrontier, Inc.', 'SpineFrontier+Inc.'],
['St Jude Medical Cardiac Rhythm Management Division', 'ST+JUDE+MEDICAL+CARDIAC+RHYTHM+MANAGEMENT+DIVISION'],
['St. Jude Medical - Neuromodulation', 'ST.+JUDE+MEDICAL+-+NEUROMODULATION'],
['St. Jude Medical, Inc., Crmd', 'ST.+JUDE+MEDICAL+INC.+CRMD'],
['Staar Surgical Co.', 'STAAR+SURGICAL+CO.'],
['Steris Corporation', 'Steris+Corporation'],
['Stryker Endoscopy', 'Stryker+Endoscopy'],
['Stryker Howmedica Osteonics Corp.', 'Stryker+Howmedica+Osteonics+Corp.'],
['Stryker Instruments Div. Of Stryker Corporation', 'Stryker+Instruments+Div.+of+Stryker+Corporation'],
['Stryker Instruments Kalamazoo', 'STRYKER+INSTRUMENTS+KALAMAZOO'],
['Stryker Instruments-Kalamazoo', 'STRYKER+INSTRUMENTS-KALAMAZOO'],
['Stryker Medical', 'STRYKER+MEDICAL'],
['Stryker Medical Division Of Stryker Corporation', 'Stryker+Medical+Division+of+Stryker+Corporation'],
['Stryker Medical-Kalamazoo', 'STRYKER+MEDICAL-KALAMAZOO'],
['Stryker Neurovascular', 'Stryker+Neurovascular'],
['Stryker Orthopaedics Mahwah', 'STRYKER+ORTHOPAEDICS+MAHWAH'],
['Stryker Orthopaedics-Mahwah', 'STRYKER+ORTHOPAEDICS-MAHWAH'],
['Surgical Instrument Service And Savings, Inc.', 'Surgical+Instrument+Service+And+Savings+Inc.'],
['Synergetics Inc', 'Synergetics+Inc'],
['Synthes (Usa)', 'SYNTHES+(USA)'],
['Synthes Gmbh', 'SYNTHES+GMBH'],
['Synthes Usa', 'SYNTHES+USA'],
['Synthes Usa Hq, Inc.', 'Synthes+USA+HQ+Inc.'],
['Synthes, Inc.', 'Synthes+Inc.'],
['Teleflex Medical', 'Teleflex+Medical'],
['Terumo Cardiovascular Systems Corp.', 'TERUMO+CARDIOVASCULAR+SYSTEMS+CORP.'],
['Terumo Cardiovascular Systems Corporation', 'Terumo+Cardiovascular+Systems+Corporation'],
['The Anspach Effort, Inc.', 'The+Anspach+Effort+Inc.'],
['Toshiba American Medical Systems Inc', 'Toshiba+American+Medical+Systems+Inc'],
['Trumpf Medical Systems, Inc.', 'Trumpf+Medical+Systems+Inc.'],
['United States Surgical Corp.', 'UNITED+STATES+SURGICAL+CORP.'],
['Unknown', 'UNKNOWN'],
['Vygon Corporation', 'Vygon+Corporation'],
['Waldemar Link Gmbh & Co. Kg (Corp. Hq.)', 'Waldemar+Link+GmbH+&+Co.+KG+(Corp.+Hq.)'],
['Westmed Inc', 'Westmed+Inc'],
['Wright Medical Technology, Inc.', 'Wright+Medical+Technology+Inc.'],
['Zimmer, Inc.', 'Zimmer+Inc.'],
['Zoll Lifecor Corporation', 'ZOLL+LIFECOR+CORPORATION'],
['Zoll Medical Corp.', 'ZOLL+MEDICAL+CORP.'],
['Zoll Medical Corporation', 'ZOLL+MEDICAL+CORPORATION'],
  ]
  $deviceList = [
['Infusion Pump', 'INFUSION+PUMP'],
['Glucose Monitoring Sys/Kit', 'GLUCOSE+MONITORING+SYS/KIT'],
['Insulin Infusion Pump', 'INSULIN+INFUSION+PUMP'],
['Insulin Infusion Pump - Sensor Augmented', 'INSULIN+INFUSION+PUMP+-+SENSOR+AUGMENTED'],
['System, Peritoneal, Automatic Delivery', 'SYSTEM,+PERITONEAL,+AUTOMATIC+DELIVERY'],
['Fluoroscopic X-Ray', 'FLUOROSCOPIC+X-RAY'],
['Implantable Cardioverter Defibrillator', 'IMPLANTABLE+CARDIOVERTER+DEFIBRILLATOR'],
['Implantable Lead', 'IMPLANTABLE+LEAD'],
['Implantable Pacing Lead', 'IMPLANTABLE+PACING+LEAD'],
['Blood Glucose Monitoring System', 'BLOOD+GLUCOSE+MONITORING+SYSTEM'],
['Intraocular Lens', 'INTRAOCULAR+LENS'],
['Permanent Pacemaker Electrode', 'PERMANENT+PACEMAKER+ELECTRODE'],
['Implantable Pulse Generator', 'IMPLANTABLE+PULSE+GENERATOR'],
['Implant', 'IMPLANT'],
['Mesh, Surgical, Polymeric', 'MESH,+SURGICAL,+POLYMERIC'],
['Defibrillation Lead', 'DEFIBRILLATION+LEAD'],
['Implantable Tachy Lead', 'IMPLANTABLE+TACHY+LEAD'],
['Defibrillator/Pacemaker', 'DEFIBRILLATOR/PACEMAKER'],
['Set, Administration, For Peritoneal Dialysis, Disposable', 'SET,+ADMINISTRATION,+FOR+PERITONEAL+DIALYSIS,+DISPOSABLE'],
['Pump, Infusion, Implanted, Programmable', 'PUMP,+INFUSION,+IMPLANTED,+PROGRAMMABLE'],
['Implantable Pacemaker/Cardio/Defib', 'IMPLANTABLE+PACEMAKER/CARDIO/DEFIB'],
['Blood Glucose Monitoring Test Strips', 'BLOOD+GLUCOSE+MONITORING+TEST+STRIPS'],
['Stimulator, Spinal-Cord, Totally Implanted For Pain Relief', 'STIMULATOR,+SPINAL-CORD,+TOTALLY+IMPLANTED+FOR+PAIN+RELIEF'],
['Generator, Oxygen, Portable', 'GENERATOR,+OXYGEN,+PORTABLE'],
['Implantable Pacemaker Pulse Generator', 'IMPLANTABLE+PACEMAKER+PULSE+GENERATOR'],
['Wearable Cardioverter Defibrillator', 'WEARABLE+CARDIOVERTER+DEFIBRILLATOR'],
['Scs Lead', 'SCS+LEAD'],
['Blood Glucose Monitoring Kit/System', 'BLOOD+GLUCOSE+MONITORING+KIT/SYSTEM'],
['Defibrillator, Automatic Implantable Cardioverter', 'DEFIBRILLATOR,+AUTOMATIC+IMPLANTABLE+CARDIOVERTER'],
['Electrode, Pacemaker, Permanent', 'ELECTRODE,+PACEMAKER,+PERMANENT'],
['Mesh, Surgical, Synthetic, Urogynecologic', 'MESH,+SURGICAL,+SYNTHETIC,+UROGYNECOLOGIC'],
['Spinal Cord Stimulator', 'SPINAL+CORD+STIMULATOR'],
['Total Hip Replacement', 'TOTAL+HIP+REPLACEMENT'],
['Staple, Implantable', 'STAPLE,+IMPLANTABLE'],
['Prosthesis, Hip', 'PROSTHESIS,+HIP'],
['Defibrillator', 'DEFIBRILLATOR'],
['Scs Ipg', 'SCS+IPG'],
['Stent, Coronary, Drug-Eluting', 'STENT,+CORONARY,+DRUG-ELUTING'],
['Ac Powered Hospital Bed', 'AC+POWERED+HOSPITAL+BED'],
['Implantable Chf Generator', 'IMPLANTABLE+CHF+GENERATOR'],
['Stimulator, Electrical, Implantable, For Incontinence', 'STIMULATOR,+ELECTRICAL,+IMPLANTABLE,+FOR+INCONTINENCE'],
['Disposable Surgical Stapler', 'DISPOSABLE+SURGICAL+STAPLER'],
['Cochlear Implant', 'COCHLEAR+IMPLANT'],
['Femoral Head', 'FEMORAL+HEAD'],
['Suture Mediated Closure', 'SUTURE+MEDIATED+CLOSURE'],
['A/C Powered Adjustable Hospital Bed', 'A/C+POWERED+ADJUSTABLE+HOSPITAL+BED'],
['A/C Powered Hospital Bed', 'A/C+POWERED+HOSPITAL+BED'],
['Blood Glucose Monitoring Test Strips - Lfr', 'BLOOD+GLUCOSE+MONITORING+TEST+STRIPS+-+LFR'],
['Set, Administration, Intravascular', 'SET,+ADMINISTRATION,+INTRAVASCULAR'],
['Replacement Heart Valve', 'REPLACEMENT+HEART+VALVE'],
['Ventilator', 'VENTILATOR'],
['Dialyzer, High Permeability With Or Without Sealed Dialysate System', 'DIALYZER,+HIGH+PERMEABILITY+WITH+OR+WITHOUT+SEALED+DIALYSATE+SYSTEM'],
['Pacer Lead', 'PACER+LEAD'],
['Instrument', 'INSTRUMENT'],
['Blood Glucose Meter', 'BLOOD+GLUCOSE+METER'],
['Drug Eluting Coronary Stent System', 'DRUG+ELUTING+CORONARY+STENT+SYSTEM'],
['Prothrombin Time Test', 'PROTHROMBIN+TIME+TEST'],
['Reservoir', 'RESERVOIR'],
['System, Endovascular Graft, Aortic Aneurysm Treatment', 'SYSTEM,+ENDOVASCULAR+GRAFT,+AORTIC+ANEURYSM+TREATMENT'],
['Picture Archiving And Communication', 'PICTURE+ARCHIVING+AND+COMMUNICATION'],
['Hip Femoral Head', 'HIP+FEMORAL+HEAD'],
['Counter, Differential Cell', 'COUNTER,+DIFFERENTIAL+CELL'],
['Pump, Infusion, Elastomeric', 'PUMP,+INFUSION,+ELASTOMERIC'],
['Hospital Wheeled Stretcher', 'HOSPITAL+WHEELED+STRETCHER'],
['Bed, Ac-Powered Adjustable Hospital', 'BED,+AC-POWERED+ADJUSTABLE+HOSPITAL'],
['Stimulator, Electrical, Implanted, For Parkinsonian Tremor', 'STIMULATOR,+ELECTRICAL,+IMPLANTED,+FOR+PARKINSONIAN+TREMOR'],
['Insulin Pump', 'INSULIN+PUMP'],
['Clinical Chemistry Analyzer', 'CLINICAL+CHEMISTRY+ANALYZER'],
['Clip, Implantable', 'CLIP,+IMPLANTABLE'],
['Surgical Mesh', 'SURGICAL+MESH'],
['Stretcher, Wheeled', 'STRETCHER,+WHEELED'],
['Wheeled Stretcher', 'WHEELED+STRETCHER'],
['Instrument, Ultrasonic Surgical', 'INSTRUMENT,+ULTRASONIC+SURGICAL'],
['Analyzer, Chemistry (Photometric, Discrete), For Clinical Use', 'ANALYZER,+CHEMISTRY+(PHOTOMETRIC,+DISCRETE),+FOR+CLINICAL+USE'],
['Blood Glucose Monitoring Device', 'BLOOD+GLUCOSE+MONITORING+DEVICE'],
['Coronary Drug-Eluting Stent', 'CORONARY+DRUG-ELUTING+STENT'],
['Defibrillator, Automatic Implantable Cardioverter, With Cardiac Resynchronizatio', 'DEFIBRILLATOR,+AUTOMATIC+IMPLANTABLE+CARDIOVERTER,+WITH+CARDIAC+RESYNCHRONIZATIO'],
['Acetabular Cup', 'ACETABULAR+CUP'],
['Wheelchair, Mechanical', 'WHEELCHAIR,+MECHANICAL'],
['Ventilator, Continuous, Facility Use', 'VENTILATOR,+CONTINUOUS,+FACILITY+USE'],
['Ac-Powered Adjustable Hospital Bed', 'AC-POWERED+ADJUSTABLE+HOSPITAL+BED'],
['Drug-Eluting Stent (Niq)', 'DRUG-ELUTING+STENT+(NIQ)'],
['Filler, Recombinant Human Bone Morphogenetic Protein, Collagen Scaffold With Met', 'FILLER,+RECOMBINANT+HUMAN+BONE+MORPHOGENETIC+PROTEIN,+COLLAGEN+SCAFFOLD+WITH+MET'],
['Breast Implant', 'BREAST+IMPLANT'],
['Phacofragmentation System', 'PHACOFRAGMENTATION+SYSTEM'],
['Pump, Infusion, Insulin', 'PUMP,+INFUSION,+INSULIN'],
['Drug Coated Stent', 'DRUG+COATED+STENT'],
['Drug-Eluting Stent', 'DRUG-ELUTING+STENT'],
['Pulse-Generator, Dual Chamber, Implantable', 'PULSE-GENERATOR,+DUAL+CHAMBER,+IMPLANTABLE'],
  ]
end

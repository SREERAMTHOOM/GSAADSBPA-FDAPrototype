require "rest-client"

class EnforcementsController < ApplicationController
  def get_content url
	#puts url
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
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?search=_exists_:recalling_firm+AND+_exists_:recall_initiation_date+AND+_exists_:status+AND+_exists_:classification+AND+recall_initiation_date:[20150101+TO+20151231]&limit=5")['results']
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
	keyName = 'term'
	@startYear = params[:startYear]
	@mfr = params[:mfr]
	@deviceType = params[:deviceType]
	#puts @startYear
	@startYear = "2015" if @startYear.nil? || @startYear.empty?
	@mfr = "Corp" if @mfr.nil? || @mfr.empty?
	@deviceType = "INSULIN+INFUSION+PUMP" if @deviceType.nil? || @deviceType.empty?
    if type == "advbymfr"
	  url = "https://api.fda.gov/device/event.json?search=manufacturer_name:" + @mfr + "+AND+_exists_:date_of_event+AND+date_received:[" + @startYear + "0101+TO+" + @startYear + "1231]&count=device.generic_name.exact"
    elsif type == "advbytype"
		url = "https://api.fda.gov/device/event.json?search=manufacturer_name:" + @mfr + "+AND+_exists_:date_of_event+AND+date_of_event:[" + @startYear + "0101+TO+" + @startYear + "1231]&count=event_type.exact"
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
		  result += "\"#{item["term"].gsub(/"/, '\\"')}\": #{item["count"]},"
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
	@deviceType = "INSULIN+INFUSION+PUMP" if @deviceType.nil? || @deviceType.empty?
	eventsUrl = "https://api.fda.gov/device/event.json?search=generic_name:" + @deviceType + "+AND+date_of_event:[" + @startYear + "0101+TO+" + @endYear + "1231]&count=date_of_event"
	enfUrl = "https://api.fda.gov/device/enforcement.json?search=reason_for_recall:" + @deviceType + "+AND+recall_initiation_date:[" + @startYear + "0101+TO+" + @endYear + "1231]&count=recall_initiation_date"
    eventData = get_content(eventsUrl)
	#puts "eventData: #{eventData}"
    enfData = get_content(enfUrl)
	#puts "enfData: #{enfData}"
	@tempData=[]
	#puts "tempData: #{@tempData}"
	if eventData.nil? || eventData.empty? || enfData.nil? || enfData.empty?
		@tempData << {name: "No Data Found", data: [["NoDataFound", 0]]}
		#puts "tempData1: #{@tempData}"
	else
		#puts "Response in reports: #{all}"
		eventResult = []
		eventData.each do |item|
		  #eventResult += "\"#{item["term"]}\", #{item["count"]},"
		  eventResult << [item["term"], item["count"]]
		end
		#eventResult = eventResult[0...-1]
		#eventResult += "]"
		@tempData << {name: "Adverse Events", data: eventResult}
		#puts "tempData2: #{@tempData}"
		enfResult = []
		enfData.each do |item|
		  #enfResult += "\"#{item["term"]}\", #{item["count"]},"
		  #enfResult += '["' + item["term"] + '",' + item["count"].to_s + "],"
		  enfResult << [item["term"], item["count"]]
		end
		#enfResult = enfResult[0...-1]
		#enfResult += "]"
		@tempData << {name: "Enforcements", data: enfResult}
		#puts "tempData3: #{@tempData}"
	end
	#puts "tempData4: #{@tempData}"
  end
  def details
    @advEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/event.json?limit=20")['results']
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?limit=20")['results']
  end
  def enfreports
    @enfEvents = JSON.parse(RestClient.get "https://api.fda.gov/device/enforcement.json?search=report_date:[20150101+TO+20151231]&limit=25&count=recalling_firm.exact")['results']
  end
  def advevents
	  @startYear = params[:startYear]
	  @mfr = params[:mfr]
	  @startYear = "2015" if @startYear.nil? || @startYear.empty?
	  @mfr = "Corp" if @mfr.nil? || @mfr.empty?
	  #url = "https://api.fda.gov/device/event.json?search=date_received:[" + @startYear + "0101+TO+" + @startYear + "0101]&count=manufacturer_name"
	  #@advByMfr = JSON.parse(RestClient.get url)['results']
	  #puts "URL : " + url
  end
  $yearList = [['2000', 2000], ['2001', 2001], ['2002', 2002], ['2003', 2003], ['2004', 2004], ['2005', 2005], ['2006', 2006], ['2007', 2007], ['2008', 2008], ['2009', 2009], ['2010', 2010], ['2011', 2011], ['2012', 2012], ['2013', 2013], ['2014', 2014], ['2015', 2015]]
  $mfrList = [
['ABBOTT DIABETES CARE INC, USA', 'ABBOTT DIABETES CARE INC, USA'],
['ABBOTT LABORATORIES', 'ABBOTT LABORATORIES'],
['Advanced Sterilization Products', 'Advanced+Sterilization+Products'],
['ALCON - IRVINE TECHNOLOGY CENTER', 'ALCON+-+IRVINE+TECHNOLOGY+CENTER'],
['Alere San Diego, Inc.', 'Alere+San+Diego,+Inc.'],
['AMERICAN MEDICAL SYSTEMS, INC.', 'AMERICAN+MEDICAL+SYSTEMS,+INC.'],
['ANIMAS CORPORATION', 'ANIMAS+CORPORATION'],
['Arrow International Inc', 'Arrow+International+Inc'],
['Atrium Medical Corporation', 'Atrium+Medical+Corporation'],
['AV-TEMECULA-CT', 'AV-TEMECULA-CT'],
['BAUSCH & LOMB', 'BAUSCH+&+LOMB'],
['BAXTER HEALTHCARE', 'BAXTER+HEALTHCARE'],
['BAXTER HEALTHCARE - IRVINE', 'BAXTER+HEALTHCARE+-+IRVINE'],
['BAXTER HEALTHCARE - LARGO', 'BAXTER+HEALTHCARE+-+LARGO'],
['BAXTER HEALTHCARE - MOUNTAIN HOME', 'BAXTER+HEALTHCARE+-+MOUNTAIN+HOME'],
['BAXTER HEALTHCARE - SINGAPORE', 'BAXTER+HEALTHCARE+-+SINGAPORE'],
['BAXTER HEALTHCARE CORP', 'BAXTER+HEALTHCARE+CORP'],
['Baxter Healthcare Corp.', 'Baxter+Healthcare+Corp.'],
['BAXTER HEALTHCARE CORPORATION', 'BAXTER+HEALTHCARE+CORPORATION'],
['BAXTER HEALTHCARE PTE. LTD.', 'BAXTER+HEALTHCARE+PTE.+LTD.'],
['BECKMAN COULTER', 'BECKMAN+COULTER'],
['Beckman Coulter Inc.', 'Beckman+Coulter+Inc.'],
['BECKMAN COULTER, INC.', 'BECKMAN+COULTER,+INC.'],
['Becton Dickinson & Co.', 'Becton+Dickinson+&+Co.'],
['Becton Dickinson & Company', 'Becton+Dickinson+&+Company'],
['Biomerieux Inc', 'Biomerieux+Inc'],
['Biomet 3i, LLC', 'Biomet+3i,+LLC'],
['Biomet Microfixation, LLC', 'Biomet+Microfixation,+LLC'],
['BIOMET ORTHOPEDICS', 'BIOMET+ORTHOPEDICS'],
['Biomet, Inc.', 'Biomet,+Inc.'],
['BIOTRONIK SE & CO. KG', 'BIOTRONIK+SE+&+CO.+KG'],
['BOSTON SCIENTIFIC', 'BOSTON+SCIENTIFIC'],
['BOSTON SCIENTIFIC - GALWAY', 'BOSTON+SCIENTIFIC+-+GALWAY'],
['BOSTON SCIENTIFIC - MAPLE GROVE', 'BOSTON+SCIENTIFIC+-+MAPLE+GROVE'],
['BOSTON SCIENTIFIC - MARLBOROUGH', 'BOSTON+SCIENTIFIC+-+MARLBOROUGH'],
['Boston Scientific Corporation', 'Boston+Scientific+Corporation'],
['BOSTON SCIENTIFIC NEUROMODULATION', 'BOSTON+SCIENTIFIC+NEUROMODULATION'],
['CARDIAC PACEMAKERS', 'CARDIAC+PACEMAKERS'],
['CARDIAC PACEMAKERS, INC', 'CARDIAC+PACEMAKERS,+INC'],
['CareFusion 303, Inc.', 'CareFusion+303,+Inc.'],
['Carestream Health Inc.', 'Carestream+Health+Inc.'],
['Carestream Health, Inc.', 'Carestream+Health,+Inc.'],
['Churchill Medical Systems, Inc.', 'Churchill+Medical+Systems,+Inc.'],
['COCHLEAR LTD.', 'COCHLEAR+LTD.'],
['Codman & Shurtleff, Inc.', 'Codman+&+Shurtleff,+Inc.'],
['ConMed Corporation', 'ConMed+Corporation'],
['Cordis Corporation', 'Cordis+Corporation'],
['CORDIS DE MEXICO', 'CORDIS+DE+MEXICO'],
['COVIDIEN', 'COVIDIEN'],
['Covidien LLC', 'Covidien+LLC'],
['Covidien LP', 'Covidien+LP'],
['CPI - DEL CARIBE', 'CPI+-+DEL+CARIBE'],
['Custom Medical Specialties, Inc.', 'Custom+Medical+Specialties,+Inc.'],
['Customed, Inc', 'Customed,+Inc'],
['CYBERONICS, INC.', 'CYBERONICS,+INC.'],
['DATASCOPE CORP.', 'DATASCOPE+CORP.'],
['Davol, Inc., Subs. C. R. Bard, Inc.', 'Davol,+Inc.,+Subs.+C.+R.+Bard,+Inc.'],
['DEPUY INTERNATIONAL', 'DEPUY+INTERNATIONAL'],
['DEPUY INTERNATIONAL, LTD.', 'DEPUY+INTERNATIONAL,+LTD.'],
['DePuy Mitek, Inc., a Johnson & Johnson Co.', 'DePuy+Mitek,+Inc.,+a+Johnson+&+Johnson+Co.'],
['DePuy Orthopaedics, Inc.', 'DePuy+Orthopaedics,+Inc.'],
['DePuy Spine, Inc.', 'DePuy+Spine,+Inc.'],
['DEPUY SYNTHES POWER TOOLS', 'DEPUY+SYNTHES+POWER+TOOLS'],
['DEPUY WARSAW', 'DEPUY+WARSAW'],
['DeRoyal Industries Inc', 'DeRoyal+Industries+Inc'],
['DEXCOM, INC.', 'DEXCOM,+INC.'],
['EDWARDS LIFESCIENCES', 'EDWARDS+LIFESCIENCES'],
['Edwards Lifesciences, LLC', 'Edwards+Lifesciences,+LLC'],
['Elekta, Inc.', 'Elekta,+Inc.'],
['ETHICON ENDO-SURGERY, INC.', 'ETHICON+ENDO-SURGERY,+INC.'],
['ETHICON ENDO-SURGERY, INC. (CINCINNATI)', 'ETHICON+ENDO-SURGERY,+INC.+(CINCINNATI)'],
['ETHICON ENDO-SURGERY, LLC', 'ETHICON+ENDO-SURGERY,+LLC'],
['ETHICON ENDO-SURGERY, LLC.', 'ETHICON+ENDO-SURGERY,+LLC.'],
['ETHICON INC.', 'ETHICON+INC.'],
['ETHICON, INC.', 'ETHICON,+INC.'],
['Exactech, Inc.', 'Exactech,+Inc.'],
['Fresenius Medical Care Holdings, Inc.', 'Fresenius+Medical+Care+Holdings,+Inc.'],
['FRESENIUS MEDICAL CARE NORTH AMERICA', 'FRESENIUS+MEDICAL+CARE+NORTH+AMERICA'],
['Gambro Renal Products, Incorporated', 'Gambro+Renal+Products,+Incorporated'],
['GE Healthcare', 'GE+Healthcare'],
['GE Healthcare, LLC', 'GE+Healthcare,+LLC'],
['GE OEC MEDICAL SYSTEMS (SLC)', 'GE+OEC+MEDICAL+SYSTEMS+(SLC)'],
['GE OEC MEDICAL SYSTEMS INC.', 'GE+OEC+MEDICAL+SYSTEMS+INC.'],
['GE OEC Medical Systems, Inc', 'GE+OEC+Medical+Systems,+Inc'],
['Genzyme Corporation, A Sanofi Company', 'Genzyme+Corporation,+A+Sanofi+Company'],
['GUIDANT CRM CLONMEL IRELAND', 'GUIDANT+CRM+CLONMEL+IRELAND'],
['HILL-ROM RITTER', 'HILL-ROM+RITTER'],
['HILL-ROM, INC.', 'HILL-ROM,+INC.'],
['HOSPIRA COSTA RICA LTD.', 'HOSPIRA+COSTA+RICA+LTD.'],
['Hospira Inc.', 'Hospira+Inc.'],
['ICU Medical, Inc.', 'ICU+Medical,+Inc.'],
['Instrumed International, Inc.', 'Instrumed+International,+Inc.'],
['Instrumentation Laboratory Co.', 'Instrumentation+Laboratory+Co.'],
['Integra LifeSciences Corp.', 'Integra+LifeSciences+Corp.'],
['Integra LifeSciences Corporation', 'Integra+LifeSciences+Corporation'],
['Intuitive Surgical, Inc.', 'Intuitive+Surgical,+Inc.'],
['INTUITIVE SURGICAL,INC.', 'INTUITIVE+SURGICAL,INC.'],
['Invacare Corporation', 'Invacare+Corporation'],
['INVACARE FLORIDA OPERATIONS', 'INVACARE+FLORIDA+OPERATIONS'],
['INVACARE TAYLOR STREET', 'INVACARE+TAYLOR+STREET'],
['Karl Storz Endoscopy America Inc', 'Karl+Storz+Endoscopy+America+Inc'],
['King Systems Corp.', 'King+Systems+Corp.'],
['LeMaitre Vascular, Inc.', 'LeMaitre+Vascular,+Inc.'],
['LIFESCAN EUROPE, A DIVISION OF CILAG GMBH INTL', 'LIFESCAN+EUROPE,+A+DIVISION+OF+CILAG+GMBH+INTL'],
['LIFESCAN INC.', 'LIFESCAN+INC.'],
['LIFESCAN, INC.', 'LIFESCAN,+INC.'],
['Linvatec Corp. dba ConMed Linvatec', 'Linvatec+Corp.+dba+ConMed+Linvatec'],
['LumiQuick Diagnostics Inc.', 'LumiQuick+Diagnostics+Inc.'],
['MDT PUERTO RICO OPERATIONS CO', 'MDT+PUERTO+RICO+OPERATIONS+CO'],
['MDT PUERTO RICO OPERATIONS CO., JUNCOS', 'MDT+PUERTO+RICO+OPERATIONS+CO.,+JUNCOS'],
['Medtronic Inc. Cardiac Rhythm Disease Management', 'Medtronic+Inc.+Cardiac+Rhythm+Disease+Management'],
['MEDTRONIC IRELAND', 'MEDTRONIC+IRELAND'],
['MEDTRONIC MED REL MEDTRONIC PUERTO RICO', 'MEDTRONIC+MED+REL+MEDTRONIC+PUERTO+RICO'],
['MEDTRONIC MED REL, INC.', 'MEDTRONIC+MED+REL,+INC.'],
['MEDTRONIC MINIMED', 'MEDTRONIC+MINIMED'],
['Medtronic Navigation, Inc.', 'Medtronic+Navigation,+Inc.'],
['Medtronic Neuromodulation', 'Medtronic+Neuromodulation'],
['MEDTRONIC PUERTO RICO OPERATIONS CO.', 'MEDTRONIC+PUERTO+RICO+OPERATIONS+CO.'],
['MEDTRONIC PUERTO RICO OPERATIONS MED-REL', 'MEDTRONIC+PUERTO+RICO+OPERATIONS+MED-REL'],
['MEDTRONIC PUERTO RICO, INC.', 'MEDTRONIC+PUERTO+RICO,+INC.'],
['MEDTRONIC S.A.', 'MEDTRONIC+S.A.'],
['Medtronic Sofamor Danek USA Inc', 'Medtronic+Sofamor+Danek+USA+Inc'],
['MEDTRONIC SOFAMOR DANEK USA, INC', 'MEDTRONIC+SOFAMOR+DANEK+USA,+INC'],
['MEDTRONIC, INC.', 'MEDTRONIC,+INC.'],
['Microtek Medical Inc', 'Microtek+Medical+Inc'],
['MPRI', 'MPRI'],
['Navilyst Medical, Inc', 'Navilyst+Medical,+Inc'],
['Nobel Biocare Usa Llc', 'Nobel+Biocare+Usa+Llc'],
['NuVasive Inc', 'NuVasive+Inc'],
['Ortho-Clinical Diagnostics', 'Ortho-Clinical+Diagnostics'],
['Orthovita, Inc., dBA Stryker Orthobiologics.', 'Orthovita,+Inc.,+dBA+Stryker+Orthobiologics.'],
['Philips Healthcare Inc.', 'Philips+Healthcare+Inc.'],
['PHILIPS MEDICAL SYSTEMS', 'PHILIPS+MEDICAL+SYSTEMS'],
['Philips Medical Systems (Cleveland) Inc', 'Philips+Medical+Systems+(Cleveland)+Inc'],
['Philips Medical Systems, Inc.', 'Philips+Medical+Systems,+Inc.'],
['Progressive Medical Inc', 'Progressive+Medical+Inc'],
['Remel Inc', 'Remel+Inc'],
['ROCHE DIAGNOSTICS', 'ROCHE+DIAGNOSTICS'],
['Roche Diagnostics Operations, Inc.', 'Roche+Diagnostics+Operations,+Inc.'],
['Roche Molecular Systems, Inc.', 'Roche+Molecular+Systems,+Inc.'],
['Siemens Healthcare Diagnostics', 'Siemens+Healthcare+Diagnostics'],
['Siemens Healthcare Diagnostics Inc', 'Siemens+Healthcare+Diagnostics+Inc'],
['Siemens Healthcare Diagnostics, Inc', 'Siemens+Healthcare+Diagnostics,+Inc'],
['Siemens Healthcare Diagnostics, Inc.', 'Siemens+Healthcare+Diagnostics,+Inc.'],
['Siemens Medical Solutions USA,  Inc', 'Siemens+Medical+Solutions+USA,++Inc'],
['Siemens Medical Solutions USA, Inc', 'Siemens+Medical+Solutions+USA,+Inc'],
['Siemens Medical Solutions USA, Inc.', 'Siemens+Medical+Solutions+USA,+Inc.'],
['Smith & Nephew Inc', 'Smith+&+Nephew+Inc'],
['Smith & Nephew, Inc. Endoscopy Division', 'Smith+&+Nephew,+Inc.+Endoscopy+Division'],
['Smiths Medical ASD, Inc.', 'Smiths+Medical+ASD,+Inc.'],
['Spinal Elements, Inc', 'Spinal+Elements,+Inc'],
['SpineFrontier, Inc.', 'SpineFrontier,+Inc.'],
['ST JUDE MEDICAL CARDIAC RHYTHM MANAGEMENT DIVISION', 'ST+JUDE+MEDICAL+CARDIAC+RHYTHM+MANAGEMENT+DIVISION'],
['ST. JUDE MEDICAL - NEUROMODULATION', 'ST.+JUDE+MEDICAL+-+NEUROMODULATION'],
['ST. JUDE MEDICAL, INC., CRMD', 'ST.+JUDE+MEDICAL,+INC.,+CRMD'],
['STAAR SURGICAL CO.', 'STAAR+SURGICAL+CO.'],
['Steris Corporation', 'Steris+Corporation'],
['Stryker Endoscopy', 'Stryker+Endoscopy'],
['Stryker Howmedica Osteonics Corp.', 'Stryker+Howmedica+Osteonics+Corp.'],
['Stryker Instruments Div. of Stryker Corporation', 'Stryker+Instruments+Div.+of+Stryker+Corporation'],
['STRYKER INSTRUMENTS KALAMAZOO', 'STRYKER+INSTRUMENTS+KALAMAZOO'],
['STRYKER INSTRUMENTS-KALAMAZOO', 'STRYKER+INSTRUMENTS-KALAMAZOO'],
['STRYKER MEDICAL', 'STRYKER+MEDICAL'],
['Stryker Medical Division of Stryker Corporation', 'Stryker+Medical+Division+of+Stryker+Corporation'],
['STRYKER MEDICAL-KALAMAZOO', 'STRYKER+MEDICAL-KALAMAZOO'],
['Stryker Neurovascular', 'Stryker+Neurovascular'],
['STRYKER ORTHOPAEDICS MAHWAH', 'STRYKER+ORTHOPAEDICS+MAHWAH'],
['STRYKER ORTHOPAEDICS-MAHWAH', 'STRYKER+ORTHOPAEDICS-MAHWAH'],
['Surgical Instrument Service And Savings, Inc.', 'Surgical+Instrument+Service+And+Savings,+Inc.'],
['Synergetics Inc', 'Synergetics+Inc'],
['SYNTHES (USA)', 'SYNTHES+(USA)'],
['SYNTHES GMBH', 'SYNTHES+GMBH'],
['SYNTHES USA', 'SYNTHES+USA'],
['Synthes USA HQ, Inc.', 'Synthes+USA+HQ,+Inc.'],
['Synthes, Inc.', 'Synthes,+Inc.'],
['Teleflex Medical', 'Teleflex+Medical'],
['TERUMO CARDIOVASCULAR SYSTEMS CORP.', 'TERUMO+CARDIOVASCULAR+SYSTEMS+CORP.'],
['Terumo Cardiovascular Systems Corporation', 'Terumo+Cardiovascular+Systems+Corporation'],
['The Anspach Effort, Inc.', 'The+Anspach+Effort,+Inc.'],
['Toshiba American Medical Systems Inc', 'Toshiba+American+Medical+Systems+Inc'],
['Trumpf Medical Systems, Inc.', 'Trumpf+Medical+Systems,+Inc.'],
['UNITED STATES SURGICAL CORP.', 'UNITED+STATES+SURGICAL+CORP.'],
['UNKNOWN', 'UNKNOWN'],
['Vygon Corporation', 'Vygon+Corporation'],
['Waldemar Link GmbH & Co. KG (Corp. Hq.)', 'Waldemar+Link+GmbH+&+Co.+KG+(Corp.+Hq.)'],
['Westmed Inc', 'Westmed+Inc'],
['Wright Medical Technology, Inc.', 'Wright+Medical+Technology,+Inc.'],
['Zimmer, Inc.', 'Zimmer,+Inc.'],
['ZOLL LIFECOR CORPORATION', 'ZOLL+LIFECOR+CORPORATION'],
['ZOLL MEDICAL CORP.', 'ZOLL+MEDICAL+CORP.'],
['ZOLL MEDICAL CORPORATION', 'ZOLL+MEDICAL+CORPORATION'],
  ]
  $deviceList = [
['INFUSION PUMP', 'INFUSION+PUMP'],
['GLUCOSE MONITORING SYS/KIT', 'GLUCOSE+MONITORING+SYS/KIT'],
['INSULIN INFUSION PUMP', 'INSULIN+INFUSION+PUMP'],
['INSULIN INFUSION PUMP - SENSOR AUGMENTED', 'INSULIN+INFUSION+PUMP+-+SENSOR+AUGMENTED'],
['SYSTEM, PERITONEAL, AUTOMATIC DELIVERY', 'SYSTEM,+PERITONEAL,+AUTOMATIC+DELIVERY'],
['FLUOROSCOPIC X-RAY', 'FLUOROSCOPIC+X-RAY'],
['IMPLANTABLE CARDIOVERTER DEFIBRILLATOR', 'IMPLANTABLE+CARDIOVERTER+DEFIBRILLATOR'],
['IMPLANTABLE LEAD', 'IMPLANTABLE+LEAD'],
['IMPLANTABLE PACING LEAD', 'IMPLANTABLE+PACING+LEAD'],
['BLOOD GLUCOSE MONITORING SYSTEM', 'BLOOD+GLUCOSE+MONITORING+SYSTEM'],
['INTRAOCULAR LENS', 'INTRAOCULAR+LENS'],
['PERMANENT PACEMAKER ELECTRODE', 'PERMANENT+PACEMAKER+ELECTRODE'],
['IMPLANTABLE PULSE GENERATOR', 'IMPLANTABLE+PULSE+GENERATOR'],
['IMPLANT', 'IMPLANT'],
['MESH, SURGICAL, POLYMERIC', 'MESH,+SURGICAL,+POLYMERIC'],
['DEFIBRILLATION LEAD', 'DEFIBRILLATION+LEAD'],
['IMPLANTABLE TACHY LEAD', 'IMPLANTABLE+TACHY+LEAD'],
['DEFIBRILLATOR/PACEMAKER', 'DEFIBRILLATOR/PACEMAKER'],
['SET, ADMINISTRATION, FOR PERITONEAL DIALYSIS, DISPOSABLE', 'SET,+ADMINISTRATION,+FOR+PERITONEAL+DIALYSIS,+DISPOSABLE'],
['PUMP, INFUSION, IMPLANTED, PROGRAMMABLE', 'PUMP,+INFUSION,+IMPLANTED,+PROGRAMMABLE'],
['IMPLANTABLE PACEMAKER/CARDIO/DEFIB', 'IMPLANTABLE+PACEMAKER/CARDIO/DEFIB'],
['BLOOD GLUCOSE MONITORING TEST STRIPS', 'BLOOD+GLUCOSE+MONITORING+TEST+STRIPS'],
['STIMULATOR, SPINAL-CORD, TOTALLY IMPLANTED FOR PAIN RELIEF', 'STIMULATOR,+SPINAL-CORD,+TOTALLY+IMPLANTED+FOR+PAIN+RELIEF'],
['GENERATOR, OXYGEN, PORTABLE', 'GENERATOR,+OXYGEN,+PORTABLE'],
['IMPLANTABLE PACEMAKER PULSE GENERATOR', 'IMPLANTABLE+PACEMAKER+PULSE+GENERATOR'],
['WEARABLE CARDIOVERTER DEFIBRILLATOR', 'WEARABLE+CARDIOVERTER+DEFIBRILLATOR'],
['SCS LEAD', 'SCS+LEAD'],
['BLOOD GLUCOSE MONITORING KIT/SYSTEM', 'BLOOD+GLUCOSE+MONITORING+KIT/SYSTEM'],
['DEFIBRILLATOR, AUTOMATIC IMPLANTABLE CARDIOVERTER', 'DEFIBRILLATOR,+AUTOMATIC+IMPLANTABLE+CARDIOVERTER'],
['ELECTRODE, PACEMAKER, PERMANENT', 'ELECTRODE,+PACEMAKER,+PERMANENT'],
['MESH, SURGICAL, SYNTHETIC, UROGYNECOLOGIC', 'MESH,+SURGICAL,+SYNTHETIC,+UROGYNECOLOGIC'],
['SPINAL CORD STIMULATOR', 'SPINAL+CORD+STIMULATOR'],
['TOTAL HIP REPLACEMENT', 'TOTAL+HIP+REPLACEMENT'],
['STAPLE, IMPLANTABLE', 'STAPLE,+IMPLANTABLE'],
['PROSTHESIS, HIP', 'PROSTHESIS,+HIP'],
['DEFIBRILLATOR', 'DEFIBRILLATOR'],
['SCS IPG', 'SCS+IPG'],
['STENT, CORONARY, DRUG-ELUTING', 'STENT,+CORONARY,+DRUG-ELUTING'],
['AC POWERED HOSPITAL BED', 'AC+POWERED+HOSPITAL+BED'],
['IMPLANTABLE CHF GENERATOR', 'IMPLANTABLE+CHF+GENERATOR'],
['STIMULATOR, ELECTRICAL, IMPLANTABLE, FOR INCONTINENCE', 'STIMULATOR,+ELECTRICAL,+IMPLANTABLE,+FOR+INCONTINENCE'],
['DISPOSABLE SURGICAL STAPLER', 'DISPOSABLE+SURGICAL+STAPLER'],
['COCHLEAR IMPLANT', 'COCHLEAR+IMPLANT'],
['FEMORAL HEAD', 'FEMORAL+HEAD'],
['SUTURE MEDIATED CLOSURE', 'SUTURE+MEDIATED+CLOSURE'],
['A/C POWERED ADJUSTABLE HOSPITAL BED', 'A/C+POWERED+ADJUSTABLE+HOSPITAL+BED'],
['A/C POWERED HOSPITAL BED', 'A/C+POWERED+HOSPITAL+BED'],
['BLOOD GLUCOSE MONITORING TEST STRIPS - LFR', 'BLOOD+GLUCOSE+MONITORING+TEST+STRIPS+-+LFR'],
['SET, ADMINISTRATION, INTRAVASCULAR', 'SET,+ADMINISTRATION,+INTRAVASCULAR'],
['REPLACEMENT HEART VALVE', 'REPLACEMENT+HEART+VALVE'],
['VENTILATOR', 'VENTILATOR'],
['DIALYZER, HIGH PERMEABILITY WITH OR WITHOUT SEALED DIALYSATE SYSTEM', 'DIALYZER,+HIGH+PERMEABILITY+WITH+OR+WITHOUT+SEALED+DIALYSATE+SYSTEM'],
['PACER LEAD', 'PACER+LEAD'],
['INSTRUMENT', 'INSTRUMENT'],
['BLOOD GLUCOSE METER', 'BLOOD+GLUCOSE+METER'],
['DRUG ELUTING CORONARY STENT SYSTEM', 'DRUG+ELUTING+CORONARY+STENT+SYSTEM'],
['PROTHROMBIN TIME TEST', 'PROTHROMBIN+TIME+TEST'],
['RESERVOIR', 'RESERVOIR'],
['SYSTEM, ENDOVASCULAR GRAFT, AORTIC ANEURYSM TREATMENT', 'SYSTEM,+ENDOVASCULAR+GRAFT,+AORTIC+ANEURYSM+TREATMENT'],
['PICTURE ARCHIVING AND COMMUNICATION', 'PICTURE+ARCHIVING+AND+COMMUNICATION'],
['HIP FEMORAL HEAD', 'HIP+FEMORAL+HEAD'],
['COUNTER, DIFFERENTIAL CELL', 'COUNTER,+DIFFERENTIAL+CELL'],
['PUMP, INFUSION, ELASTOMERIC', 'PUMP,+INFUSION,+ELASTOMERIC'],
['HOSPITAL WHEELED STRETCHER', 'HOSPITAL+WHEELED+STRETCHER'],
['BED, AC-POWERED ADJUSTABLE HOSPITAL', 'BED,+AC-POWERED+ADJUSTABLE+HOSPITAL'],
['STIMULATOR, ELECTRICAL, IMPLANTED, FOR PARKINSONIAN TREMOR', 'STIMULATOR,+ELECTRICAL,+IMPLANTED,+FOR+PARKINSONIAN+TREMOR'],
['INSULIN PUMP', 'INSULIN+PUMP'],
['CLINICAL CHEMISTRY ANALYZER', 'CLINICAL+CHEMISTRY+ANALYZER'],
['CLIP, IMPLANTABLE', 'CLIP,+IMPLANTABLE'],
['SURGICAL MESH', 'SURGICAL+MESH'],
['STRETCHER, WHEELED', 'STRETCHER,+WHEELED'],
['WHEELED STRETCHER', 'WHEELED+STRETCHER'],
['INSTRUMENT, ULTRASONIC SURGICAL', 'INSTRUMENT,+ULTRASONIC+SURGICAL'],
['ANALYZER, CHEMISTRY (PHOTOMETRIC, DISCRETE), FOR CLINICAL USE', 'ANALYZER,+CHEMISTRY+(PHOTOMETRIC,+DISCRETE),+FOR+CLINICAL+USE'],
['BLOOD GLUCOSE MONITORING DEVICE', 'BLOOD+GLUCOSE+MONITORING+DEVICE'],
['CORONARY DRUG-ELUTING STENT', 'CORONARY+DRUG-ELUTING+STENT'],
['DEFIBRILLATOR, AUTOMATIC IMPLANTABLE CARDIOVERTER, WITH CARDIAC RESYNCHRONIZATIO', 'DEFIBRILLATOR,+AUTOMATIC+IMPLANTABLE+CARDIOVERTER,+WITH+CARDIAC+RESYNCHRONIZATIO'],
['ACETABULAR CUP', 'ACETABULAR+CUP'],
['WHEELCHAIR, MECHANICAL', 'WHEELCHAIR,+MECHANICAL'],
['VENTILATOR, CONTINUOUS, FACILITY USE', 'VENTILATOR,+CONTINUOUS,+FACILITY+USE'],
['AC-POWERED ADJUSTABLE HOSPITAL BED', 'AC-POWERED+ADJUSTABLE+HOSPITAL+BED'],
['DRUG-ELUTING STENT (NIQ)', 'DRUG-ELUTING+STENT+(NIQ)'],
['FILLER, RECOMBINANT HUMAN BONE MORPHOGENETIC PROTEIN, COLLAGEN SCAFFOLD WITH MET', 'FILLER,+RECOMBINANT+HUMAN+BONE+MORPHOGENETIC+PROTEIN,+COLLAGEN+SCAFFOLD+WITH+MET'],
['BREAST IMPLANT', 'BREAST+IMPLANT'],
['PHACOFRAGMENTATION SYSTEM', 'PHACOFRAGMENTATION+SYSTEM'],
['PUMP, INFUSION, INSULIN', 'PUMP,+INFUSION,+INSULIN'],
['DRUG COATED STENT', 'DRUG+COATED+STENT'],
['DRUG-ELUTING STENT', 'DRUG-ELUTING+STENT'],
['PULSE-GENERATOR, DUAL CHAMBER, IMPLANTABLE', 'PULSE-GENERATOR,+DUAL+CHAMBER,+IMPLANTABLE'],
  ]
end

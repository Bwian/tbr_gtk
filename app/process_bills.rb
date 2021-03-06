require_relative 'services'
require_relative 'call_type'
require_relative 'service'
require_relative 'service_summary'
require_relative 'call_detail'
require_relative 'group'
require_relative 'groups'
require_relative 'create_files'
require_relative 'parse_files'
require_relative 'log_it'
require_relative 'progress_it'

class ProcessBills

  UNASSIGNED	= 'Unassigned'  
  
  def initialize
    @log = LogIt.instance
    @textview = nil
    @pb = ProgressIt.instance
  end
  
  def run (services_file,bill_file,replace)
    @log.info("Starting Telstra Billing Data Extract")

    @log.info("Extracting Call Types from #{bill_file}")
    call_type = CallType.new
    call_type.load(bill_file)

    services = Services.new
    groups = Groups.new

    @log.info("Mapping services from #{services_file}")
    ParseFiles.map_services(groups,services,services_file)
    @log.info("Extracting billing data from #{bill_file}")
    invoice_date = ParseFiles.parse_bill_file(services,call_type,bill_file)

    @log.info("Building Unassigned group")
    group = groups.group(UNASSIGNED)
    services.each do |service|
    	group.add_service(service) if service.name == UNASSIGNED
    end

    @pb.total = groups.size + services.size + 2 # totals plus archive
    
    cf = CreateFiles.new(invoice_date,replace)
    @log.info("Creating group summaries")
    groups.each do |group|
    	@pb.increment
      cf.group_summary(group)
    end

    @log.info("Creating service details")
    services.each do |service|
    	@pb.increment
      cf.call_details(service)
    end

    @log.info("Creating service totals summary")
    @pb.increment
    cf.service_totals(services)

    @pb.increment
    CreateFiles.archive(bill_file)
    
    @log.info("PDF report files can be found in #{cf.dir_full_root}.") 
    @log.info("Telstra billing data extract completed.") 
  end 
end

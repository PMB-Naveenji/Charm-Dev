/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDComplaintReportController.
* @Why   : Handles all the customization involved on reports of Complaint object.
* @When  : 30-AUG-2018.
* @Where : From ComplaintReport Visualforce page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    30-AUG-2018            Work ID / Case ID        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit               Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    28-JUL-2020            Code Audit               Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDComplaintReportController {

	public List<ComplaintTicketReportResult> tickets {set; get;}
	public LineSplitter lineSpltr {get; set;}

	/*
	* @Method       : Constructor.
	* @Description  : To handle all the logic in ADDComplaintReportController class.
	* @Invoke       : From ComplaintReport page.
	* @Return       : N/A.
	* @Params       : N/A.
	*/
	public ADDComplaintReportController() {
		lineSpltr = new LineSplitter();
		tickets = new List<ComplaintTicketReportResult>();
		String ticketIds = ApexPages.CurrentPage().getparameters().get('ids');
		if(ticketIds != null) {
				List<String> ticketNumbers = ticketIds.split('[ ;,.]+');
				system.debug(ticketNumbers);
				tickets = ComplaintTicketReport.Generate(ticketNumbers);
		}
	}
}
/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketProdEvalWrapper.
* @Why   : Class to wrap Ticekt Product Eval records.
* @When  : 13-JAN-2017.
* @Where : From ComplaintTicketReport, ComplaintTicketReportController, ComplaintTicketReportResult classes.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                     Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  13-JAN-2017            Work ID / Case ID                   Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                          Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class TicketProdEvalWrapper {
    public Ticket_Product_Evaluation_Investigation__c obj { get; set; }
    public List<Task_Product_Evaluation_Investigation__c> tasks { get; set; }

    /*
    * @Method       : TicketProdEvalWrapper.
    * @Description  : Constructor.
    * @Invoke       : From TicketProdEvalWrapper class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public TicketProdEvalWrapper() {
        obj = new Ticket_Product_Evaluation_Investigation__c();
        tasks = new List<Task_Product_Evaluation_Investigation__c>();
    }
}
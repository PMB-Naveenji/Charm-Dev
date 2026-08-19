/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateSearchResultRecords class is to avoid Apex CPU time IdLimit exception.
* @Why   : Class to insert the Ticket_Search_Result__c records in asynchronous mode.
* @When  : 23-AUG-2018.
* @Where : From ADDS5DynamicSearchController Class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                     Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  23-AUG-2018            Work ID / Case ID                   Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                          Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

Public class UpdateSearchResultRecords implements Queueable{

    private List<Ticket_Search_Result__c> ticketSearchResultUpdateList;
    private List<Id> ticketSearchResultUpdateListIDs = New List<Id>();

    /*
    * @Method       : UpdateSearchResultRecords.
    * @Description  : Constructor.
    * @Invoke       : From ADDS5DynamicSearchController Class.
    * @Return       : N/A.
    * @Params       : List<Ticket_Search_Result__c> ticketSearchResultUpdateListTTemp.
    */
    public UpdateSearchResultRecords(List<Ticket_Search_Result__c> ticketSearchResultUpdateListTTemp){
        this.ticketSearchResultUpdateList = ticketSearchResultUpdateListTTemp;
    }

    /*
    * @Method       : execute.
    * @Description  : To insert the Ticket_Search_Result__c records.
    * @Invoke       : From UpdateSearchResultRecords class.
    * @Return       : N/A.
    * @Params       : QueueableContext context.
    */
    public void execute(QueueableContext context) {
        if(ticketSearchResultUpdateList.size() > 0){
            insert this.ticketSearchResultUpdateList;
            for(Ticket_Search_Result__c objTicketSearchResult : this.ticketSearchResultUpdateList){
                ticketSearchResultUpdateListIDs.add(objTicketSearchResult.Id);
            }
            //Added - W-000378
            if(ticketSearchResultUpdateListIDs.size() > 0){
                ADDUtil.processTicketSearchResults(ticketSearchResultUpdateListIDs);
            }
        }
    }
}
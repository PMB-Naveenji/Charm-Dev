/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateTicketSearchResults.
* @Why   : To call global  class, used for updating the value of Is Ticket Adverse Event? field in Ticket
*           search if Ticket Was an adverse event identified field change.
*           UpdateTicketSearchResults class for processing Ticket search records in batches.
* @When  : 12-FEB-2019.
* @Where : From Process Builder - Update adverse event status on ticket search.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  12-FEB-2019            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class UpdateTicketSearchResults {
    /*
    * @Method       : updateTicketSearchResultAdverseEvent.
    * @Description  : processing Ticket search records in batches.
    * @Invoke       : From Process Builder -  Update adverse event status on ticket search.
    * @Return       : N/A.
    * @Params       : List<Id> records.
    */
    @InvocableMethod
    public static void updateTicketSearchResultAdverseEvent(List<Id> records){
        //26APR19 - #803, #804 -
        // Is there any better way?
        List<Ticket_Search_Result__c> lstTicketSearchResults = New List<Ticket_Search_Result__c>();
        for(Ticket_Search_Result__c objTicketSearchResult : [SELECT Id, Is_Ticket_Adverse_Event__c,Ticket__r.Was_an_Adverse_Event_Identified__c, Ticket__c FROM Ticket_Search_Result__c WHERE Ticket__c IN : records ORDER BY CreatedDate DESC LIMIT 49900 ]){
            if(objTicketSearchResult.Is_Ticket_Adverse_Event__c != objTicketSearchResult.Ticket__r.Was_an_Adverse_Event_Identified__c){
                objTicketSearchResult.Is_Ticket_Adverse_Event__c = objTicketSearchResult.Ticket__r.Was_an_Adverse_Event_Identified__c;
                lstTicketSearchResults.add(objTicketSearchResult);
            }
        }

        if(lstTicketSearchResults.size() > 0 && lstTicketSearchResults.size() < 9950)
            Update lstTicketSearchResults;
        //26APR19 - Commented as Batch cannot be called from other batch execute method
        //UpdateTicketSearchAdverseEvent searchResultBatch = new UpdateTicketSearchAdverseEvent(records) ;
        //ID batchprocessid = Database.executeBatch(searchResultBatch);

    }
}
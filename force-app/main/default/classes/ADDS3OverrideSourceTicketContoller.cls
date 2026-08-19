/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3OverrideSourceTicketContoller.
* @Why   : Handles all the customization involved on ADDS3OverrideSourceTicket page.
* @When  : 23-MAR-2017.
* @Where : From ADDS3OverrideSourceTicket page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID          Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				   23-MAR-2017			  Work ID / Case ID        Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit               Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit               Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    12-AUG-2020            Code Audit               Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3OverrideSourceTicketContoller{

    public List< CMPL123CME__Complaint__c > results{get;set;} //search results
    public string searchText{get;set;} //search keyword
    public string recordIds{get;set;}
    public string selectedTicketId{get;set;}
    public Boolean isSuccess{set;get;}
    String ticketId;

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDS3OverrideSourceTicket page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ADDS3OverrideSourceTicketContoller(){

        isSuccess = false;
        recordIds = System.currentPageReference().getParameters().get('ids');
        searchText = System.currentPageReference().getParameters().get('lksrch');
        ticketId = System.currentPageReference().getParameters().get('tid');
        runSearch();
    }

    /*
    * @Method       : search.
    * @Description  : To perform the keyword search.
    * @Invoke       : From ADDS3OverrideSourceTicket Page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference search(){
        runSearch();
        return null;
    }

    /*
    * @Method       : runSearch.
    * @Description  : To run search by calling performSearch method.
    * @Invoke       : From ADDS3OverrideSourceTicket Page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private void runSearch () {
        // TODO prepare query string for complex searches & prevent injections
        results = performSearch(searchText);

    }

    /*
    * @Method       : performSearch.
    * @Description  : To perform the search and return the list of records.
    * @Invoke       : From ADDS3OverrideSourceTicket class.
    * @Return       : List<CMPL123CME__Complaint__c>.
    * @Params       : string searchText.
    */
    public List<CMPL123CME__Complaint__c> performSearch(string searchText){

        String queryString = 'SELECT Id';
        Set<String> defaultFields = new Set<String>{'Id'};

        for(Schema.FieldSetMember f : SObjectType.CMPL123CME__Complaint__c.FieldSets.ADDS3_Override_Source_Ticket.getFields()){
            if(!defaultFields.contains(f.getFieldPath())){
                queryString += ',' + f.getFieldPath() ;
            }
        }

        queryString = queryString + ' FROM CMPL123CME__Complaint__c';

        if(searchText != '' && searchText != null){
            queryString = queryString +  ' WHERE Id != :ticketId AND (Name LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'';
            for(Schema.FieldSetMember f : SObjectType.CMPL123CME__Complaint__c.FieldSets.ADDS3_Override_Source_Ticket.getFields()){
                if(f.getFieldPath() != 'Name'){
                    queryString = queryString+' OR '+f.getFieldPath()+' LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'' ;
                }
            }
            queryString = queryString + ')';
        }
        queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 25';
        return database.query(queryString);

    }

    /*
    * @Method       : overrideTicket.
    * @Description  : To run the record id on junction recordid.
    * @Invoke       : From ADDS3OverrideSourceTicket page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference overrideTicket(){

        if(recordIds != null){
            List<sobject> updatableRecords = new List<sobject>();
            recordIds = recordIds.removeEnd(',');
            Set<String> junctionRecordIds = new Set<String>();
            Set<String> investigationIds = new Set<String>();
            junctionRecordIds.addAll(recordIds.split(','));
            for(Ticket_Product_Evaluation_Investigation__c junctionRecord : [SELECT Id, Investigation_Evaluation__c, Ticket__c
                FROM Ticket_Product_Evaluation_Investigation__c Where Id IN: junctionRecordIds]){
                investigationIds.add(junctionRecord.Investigation_Evaluation__c);
                updatableRecords.add(new Ticket_Product_Evaluation_Investigation__c(Id = junctionRecord.Id, Ticket__c = selectedTicketId));
            }

            for(String investigationId : investigationIds){
                updatableRecords.add(new CMPL123CME__Investigation__c(Id = investigationId, CMPL123CME__Complaint__c = selectedTicketId));
            }

            if(updatableRecords.size() > 0){
                try{
                    update updatableRecords;
                }catch(Exception exp){
                    ApexPages.addMessages(exp);
                    isSuccess = true;
                }
            }
        }
        return null;
    }

}
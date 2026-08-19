/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDS3OverrideInvestigationController.
* @Why   : Handles all the customization involved on ADDS3OverrideSourceInvestigation page.
* @When  : 23-MAR-2017.
* @Where : From ADDS3OverrideSourceInvestigation page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				 23-MAR-2017			Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                  15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                  12-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3OverrideInvestigationController {

    public List<CMPL123CME__Investigation__c> results{get;set;} //search results
    public string searchText{get;set;} //search keyword
    public string recordIds{get;set;}
    public string selectedInvestigationId{get;set;}
    public Boolean isSuccess{set;get;}
    String investigationId;

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDS3OverrideSourceInvestigation page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ADDS3OverrideInvestigationController(){

        isSuccess = false;
        recordIds = System.currentPageReference().getParameters().get('ids');
        searchText = System.currentPageReference().getParameters().get('lksrch');
        investigationId = System.currentPageReference().getParameters().get('pid');
        runSearch();
    }

    /*
    * @Method       : search.
    * @Description  : To perform the keyword search.
    * @Invoke       : From ADDS3OverrideSourceInvestigation Page.
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
    * @Invoke       : From ADDS3OverrideSourceInvestigation Page.
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
    * @Invoke       : From ADDS3OverrideInvestigationController class.
    * @Return       : List<CMPL123CME__Investigation__c>.
    * @Params       : string searchText.
    */
    public List<CMPL123CME__Investigation__c> performSearch(string searchText) {

        String queryString = 'SELECT Id';
        Set<String> defaultFields = new Set<String>{'Id'};

        for(Schema.FieldSetMember f : SObjectType.CMPL123CME__Investigation__c.FieldSets.ADDS3_Leverage_Investigation_Search.getFields()){
            if(!defaultFields.contains(f.getFieldPath())){
                queryString += ',' + f.getFieldPath();
            }
        }

        queryString = queryString + ' FROM CMPL123CME__Investigation__c';

        if(searchText != '' && searchText != null) {
            queryString = queryString +  ' WHERE Id != :investigationId AND (Name LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'';
            for(Schema.FieldSetMember f : SObjectType.CMPL123CME__Investigation__c.FieldSets.ADDS3_Leverage_Investigation_Search.getFields()){
                if(f.getFieldPath() != 'Name' && String.valueOf(f.getType()) != 'REFERENCE' && String.valueOf(f.getType()) != 'BOOLEAN'
                && String.valueOf(f.getType()) != 'DATE' && String.valueOf(f.getType()) != 'DATETIME'){
                    queryString = queryString+' OR '+f.getFieldPath()+' LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'' ;
                }
            }
            queryString = queryString + ')';
        }
        queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 25';
        return database.query(queryString);
    }

    /*
    * @Method       : overrideInvestigation.
    * @Description  : To run on junction record id for updatable records.
    * @Invoke       : From ADDS3OverrideSourceInvestigation Page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference overrideInvestigation(){
        if(recordIds != null){
            List<sobject> updatableRecords = new List<sobject>();
            recordIds = recordIds.removeEnd(',');
            Set<String> junctionRecordIds = new Set<String>();
            Set<String> taskIds = new Set<String>();
            junctionRecordIds.addAll(recordIds.split(','));
            for(Task_Product_Evaluation_Investigation__c junctionRecord : [SELECT Id, Investigation_Evaluation__c, Task__c
                FROM Task_Product_Evaluation_Investigation__c Where Id IN: junctionRecordIds]){
                taskIds.add(junctionRecord.Task__c);
                updatableRecords.add(new Task_Product_Evaluation_Investigation__c(Id = junctionRecord.Id, Investigation_Evaluation__c = selectedInvestigationId));
            }

            for(String taskId : taskIds){
                updatableRecords.add(new Task__c(Id = taskId, Related_Investigation_Evaluation__c = selectedInvestigationId));
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
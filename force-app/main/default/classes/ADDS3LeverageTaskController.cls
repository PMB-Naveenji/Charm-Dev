/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3LeverageTaskController.
* @Why   : Handles all the customization involved on ADDS3LeverageTask page.
* @When  : 05-OCT-2018.
* @Where : From ADDS3LeverageTask page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				 05-OCT-2018			Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                  15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                  12-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3LeverageTaskController{

    public List< Task__c > results{get;set;} // search results
    public string searchText{get;set;} //search keyword
    public string recordId{get;set;}
    public string selectedTaskId{get;set;}
    public Boolean isSuccess{set;get;}

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDS3LeveragedTask page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ADDS3LeverageTaskController(){
        isSuccess = false;
        recordId = System.currentPageReference().getParameters().get('id');
        searchText = System.currentPageReference().getParameters().get('lksrch');
        runSearch();
    }

    /*
    * @Method       : search.
    * @Description  : To perform the keyword search.
    * @Invoke       : From ADDS3LeverageTask Page.
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
    * @Invoke       : From ADDS3LeverageTask Page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    private void runSearch() {
        // TODO prepare query string for complex searches & prevent injections
        results = performSearch(searchText);
    }

    /*
    * @Method       : performSearch.
    * @Description  : To perform the search and return the list of records.
    * @Invoke       : From ADDS3LeverageTaskController class.
    * @Return       : List<Task__c>.
    * @Params       : string searchText.
    */
    public List< Task__c > performSearch(string searchText){

        String queryString = 'SELECT Id ';
        Set<String> defaultFields = new Set<String>{'Id'};

            for(Schema.FieldSetMember f : SObjectType.Task__c.FieldSets.Leverage_Task_Search_Popup.getFields()){
                if(!defaultFields.contains(f.getFieldPath())){
                    queryString += ',' + f.getFieldPath() ;
                }
            }
         queryString = queryString + ' FROM Task__c';

        // Removed - W-000386 - CMPL123_WF_Status__c != \'Closed-Done\' on below query
        // Added - W-000383 -  Related_Investigation_Evaluation__r.CMPL123_WF_Status__c != \'Closed-Voided\'
        queryString = queryString +  ' WHERE CMPL123_WF_Status__c != \'Closed-Voided\' AND Related_Investigation_Evaluation__r.CMPL123_WF_Status__c != \'Closed-Voided\'';

        if(searchText != '' && searchText != null){
            queryString = queryString +  'AND (Name LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'';
            for(Schema.FieldSetMember f : SObjectType.Task__c.FieldSets.Leverage_Task_Search_Popup.getFields()){
                //Removed - W-000154 -  Condition removed - && String.valueOf(f.getType()) != 'TEXTAREA'
                if(f.getFieldPath() != 'Name' && String.valueOf(f.getType()) != 'REFERENCE' && String.valueOf(f.getType()) != 'BOOLEAN'
                   && String.valueOf(f.getType()) != 'DATETIME' && String.valueOf(f.getType()) != 'DATE' ){//&& String.valueOf(f.getType()) != 'TEXTAREA'
                       queryString = queryString+' OR '+f.getFieldPath()+' LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'' ;
                   }

                //Added - W-000154 - Task Type Search - Start
                if(String.valueOf(f.getType()) == 'REFERENCE' && f.getFieldPath() == 'RecordTypeId'){
                    queryString = queryString+' OR RecordType.Name LIKE \'%' + String.escapeSingleQuotes(searchText) +'%\'' ;
                }
                //Added - W-000154 - Task Type Search - End
            }
            queryString = queryString + ')';
        }
        queryString = queryString + ' ORDER BY CreatedDate DESC LIMIT 25';
        return database.query(queryString);
    }

    /*
    * @Method       : leverageSelectedTask.
    * @Description  : To will leverage all the selected task records for the particular parent investigation by inserting a junction record.
    * @Invoke       : From ADDS3LeverageTask Page.
    * @Return       : PageReference.
    * @Params       : N/A.
    */
    public PageReference leverageSelectedTask() {
        if(selectedTaskId != null && recordId != null){

            List<Task_Product_Evaluation_Investigation__c> productInvestigationTasks = new List<Task_Product_Evaluation_Investigation__c>();
            for(String taskId : selectedTaskId.split(';')){
                String taskIdValue = taskId.split('-')[0];
                String rationale;
                if(taskId.substringAfter('-') != '' && taskId.substringAfter('-').length() > 0){
                    rationale = taskId.split('-')[1];
                productInvestigationTasks.add(new Task_Product_Evaluation_Investigation__c(Task__c = taskIdValue,
                                                                                           Investigation_Evaluation__c = recordId, Leverage_Rationale__c = rationale, Source_Leveraged__c = 'Leveraged'));
                }
            }
            try{
                Security.stripInaccessible(AccessType.CREATABLE, productInvestigationTasks);
                insert productInvestigationTasks;
                isSuccess = false;
            }catch(Exception exp){
                ApexPages.addMessages(exp);
                isSuccess = true;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,Label.Ticket_Product_Evaluation_Investigation_Select_One));
            isSuccess = true;
        }
        return null;
    }
}
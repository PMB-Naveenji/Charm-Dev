/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3LeveragedTaskListController.
* @Why   : Handles all the customization involved on ADDS3LeveragedTaskList page.
* @When  : 14-AUG-2018.
* @Where : From ADDS3LeveragedTaskList page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				   14-AUG-2018			  Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    12-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    07-SEP-2020            PMD Sanitizing            Added escaping of special sensitive symbols to url param.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDS3LeveragedTaskListController {

    public List< Task_Product_Evaluation_Investigation__c > childTasks {set;get;}
    Public String keyPrefix{set;get;}
    Public String taskKeyPrefix{set;get;}
    Public String investigationId{set;get;}
    Public String investigationName{set;get;}
    private ApexPages.StandardController standardController;
    Public Boolean displayButtons{set;get;}
    public String disconnectedId{set;get;}
    Public String complaintId{set;get;}
    Public String complaintName{set;get;}
    // declared variable for cloning User story
    public String taskId{set;get;}

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : From ADDS3LeveragedTaskList page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController standardController.
    */
    public ADDS3LeveragedTaskListController(ApexPages.StandardController standardController){

        this.standardController = standardController;
        // PMD Sanitizing: added escapeJava() method
        String investigationIdParam = ApexPages.currentPage().getParameters().get('id');
        investigationId = investigationIdParam != null ? investigationIdParam.escapeJava() : null;
        childTasks = new List<Task_Product_Evaluation_Investigation__c>();
        taskKeyPrefix = Task__c.sObjectType.getDescribe().getKeyPrefix();
        displayButtons = false;
        if(!Test.isRunningTest()){
            this.standardController.addFields(new List<String>{'Name', 'CMPL123_WF_Status__c','CMPL123CME__Complaint__c'});
        }
        CMPL123CME__Investigation__c currentInvestgation = (CMPL123CME__Investigation__c)standardController.getRecord();
        InvestigationName = currentInvestgation.Name;
        complaintId = currentInvestgation.CMPL123CME__Complaint__c;
        if(currentInvestgation.CMPL123_WF_Status__c == 'Assess' || currentInvestgation.CMPL123_WF_Status__c == 'In Process-Evaluation' || currentInvestgation.CMPL123_WF_Status__c == 'In Process-Investigation') {
            displayButtons = true;
        }

        if(complaintId != null) {
            complaintName = [SELECT Name FROM CMPL123CME__Complaint__c Where Id= :complaintId LIMIT 1].Name;
        }

        if(investigationId != null){
            keyPrefix = investigationId.substring(0,3);
            String queryString = 'SELECT Id, Investigation_Evaluation__c, Task__c, Name, Source_Leveraged__c, Leverage_Rationale__c, Task__r.CMPL123_WF_Status__c';
            String returnList = ApexPages.currentPage().getParameters().get('q');
            Set<String> defaultFields = new Set<String>{'Id', 'Investigation_Evaluation__c', 'Task__c', 'Name', 'Source_Leveraged__c', 'Leverage_Rationale__c', 'Task__r.CMPL123_WF_Status__c'};

            for(Schema.FieldSetMember f : SObjectType.Task_Product_Evaluation_Investigation__c.FieldSets.ADDS3_Leveraged_Tasks_on_Investigation.getFields()){
                if(!defaultFields.contains(f.getFieldPath())){
                    queryString += ',' + f.getFieldPath() ;
                }
            }

            queryString = queryString + ' FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__c =: investigationId';
            if(returnList != null){
                queryString = queryString + ' ORDER BY DESC';
            }else{
                queryString = queryString + ' ORDER BY CreatedDate DESC'; //LIMIT 10
            }
            childTasks = Database.query(queryString);
            // childTasks = Security.stripInaccessible(AccessType.READABLE, childTasks).getRecords();
        }
    }

    /*
    * @Method       : disconnectTasks.
    * @Description  : To disconnect Leveraged tasks that are related to Evaluation/Investigation.
    * @Invoke       : From ADDS3LeveragedTaskList page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void disconnectTasks(){
        if(disconnectedId != null && disconnectedId != ''){
            List<Id> taskIdSet = disconnectedId.split(';');
            if ([SELECT COUNT() FROM Task_Product_Evaluation_Investigation__c Where Id IN: taskIdSet] > 0){
                delete [SELECT Id FROM Task_Product_Evaluation_Investigation__c Where Id IN: taskIdSet];
            }
        }
    }

    /*
    * @Method       : deleteTasks.
    * @Description  : To delete Source tasks that are related to Evaluation/Investigation.
    * @Invoke       : From ADDS3LeveragedTaskList page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    //Added W-000066
    public void deleteTasks(){
        ADDS3LeveragedTaskListControllerHelper.deleteTasks(disconnectedId);
    }

    /*
    * @Method       : cloneAndClaimAction.
    * @Description  : To clone and claiming the task.
    * @Invoke       : From ADDS3LeveragedTaskList page.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // code changes for clone and claiming the task
    public void cloneAndClaimAction(){
        Set<String> excludeFieldSet = new Set<String>{'ownerid','isdeleted','createddate','createdbyid',
                                                          'lastmodifieddate','lastmodifiedbyid','systemmodstamp',
                                                          'lastactivitydate','lastvieweddate','lastreferenceddate',
                                                          'cmpl123rule_key_value__c','cmpl123_wf_status__c',
                                                          'cmpl123_wf_action_performed_on__c',
                                                          'cmpl123_wf_action_performed_by__c',
                                                          'cmpl123_wf_action__c','cmpl123task_key_value__c'};
        if(taskId!= null && taskId!= ''){
            List<String> junctionTaskIdList = taskId.split(';');
            Set<String> taskIdSet = new Set<String>();
            List<Task_Product_Evaluation_Investigation__c > taskList = [SELECT Task__c FROM Task_Product_Evaluation_Investigation__c WHERE Id=: junctionTaskIdList ] ;
            for(Task_Product_Evaluation_Investigation__c task:taskList){
                taskIdSet.add(task.Task__c);
            }
            List<Task__c> clonedTaskList = new List<Task__c>();
            List<Task__c> clonedTaskUpdateList = new List<Task__c>();
            Schema.DescribeSObjectResult describeResult = Task__c.sObjectType.getDescribe();
            String fieldsQueryString = '';
            String queryString = '';
            for(String apiName : describeResult.fields.getMap().keySet()){
               if(!excludeFieldSet.contains(apiName)){
                   fieldsQueryString +=  apiName + ',' ;
               }
            }
            fieldsQueryString = fieldsQueryString.removeEnd(',');
            queryString = 'SELECT ' + fieldsQueryString + ' FROM Task__c WHERE Id =:taskIdSet';
            clonedTaskList = Database.query(queryString);
            clonedTaskUpdateList.addAll(clonedTaskList.deepClone(false));
            for(Task__c task :clonedTaskUpdateList){
               task.Related_Investigation_Evaluation__c = investigationId;

            }
            insert clonedTaskUpdateList;
            // delete the junction record
            delete [SELECT Id FROM Task_Product_Evaluation_Investigation__c Where Id IN: junctionTaskIdList];
            List<Task_Product_Evaluation_Investigation__c> taskProdInvestigationList = new List<Task_Product_Evaluation_Investigation__c >();
            for(Task__c  task:clonedTaskUpdateList){
              taskProdInvestigationList.add(new Task_Product_Evaluation_Investigation__c(Task__c = task.id,
                    Investigation_Evaluation__c = investigationId, Source_Leveraged__c = 'Source'));
            }
            //insert taskProdInvestigationList;
        }
    }
    // end
}
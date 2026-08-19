/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDTrendItemHandler
* @Why   : Handles all the customization involved on ADDTrend item maintainance request handler object.
* @When  : 07-MAR-2017
* @Where : From Trend_Item_AuditTrigger trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                  Modification ID       Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*      Admin                07-MAR-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*      oivan                05-JAN-2020            TWD Upgrade issue     Added method wfLogic().
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ADDTrendItemHandler extends TriggerHandler {

    static Map<String, String> recordTypeMap;
    static String thresholdRecordTypeId;
    static String ticketTT;
    static String submissionTT;
    static List<SObjectField> ticketTTComplaintRequiredFields = new List<SObjectField>{
            Trend_Item__c.EWMA_Mean__c,
            Trend_Item__c.EWMA_Standard_Deviation__c,
            Trend_Item__c.Date_Range_From_date_Compliant__c,
            Trend_Item__c.Base_Line_Execution_Date_Compliant__c,
            Trend_Item__c.IR_Mean__c,
            Trend_Item__c.IR_Upper_Limit__c,
            Trend_Item__c.IR_Lower_Limit__c,
            Trend_Item__c.Date_Range_To_Compliant__c
    };
    static List<SObjectField> ticketTTServiceRequiredFields = new List<SObjectField>{
            Trend_Item__c.EWMA_Mean_Service__c,
            Trend_Item__c.EWMA_Standard_Deviation_Service__c,
            Trend_Item__c.Date_Range_From_date_Service__c,
            Trend_Item__c.Base_Line_Execution_Date_Service__c,
            Trend_Item__c.IR_Mean_Service__c,
            Trend_Item__c.IR_Upper_Limit_Service__c,
            Trend_Item__c.IR_Lower_Limit_Service__c,
            Trend_Item__c.Date_Range_To_Service__c
    };
    static List<SObjectField> submissionTTRequiredFields = new List<SObjectField>{
            Trend_Item__c.EWMA_PBAR__c,
            Trend_Item__c.EWMA_PBAR_MDI__c
    };

/**
* @Method       : getRecordTypes
* @Invoke       : From ADDTrendItemHandler class
* @Description  : Method to fetch the record type
* @Return       : N/A
* @Params       : N/A
**/     
    public static void getRecordTypes() {
        if(recordTypeMap == null) {
            recordTypeMap = ADDUtil.getRecordTypeMap('Trend_Item__c');
            thresholdRecordTypeId = recordTypeMap.get('Thresholds');
            submissionTT = recordTypeMap.get('Submission T/T');
            ticketTT = recordTypeMap.get('Ticket T/T');
        }  
    }

    /**
* @Method       : isRequiredFieldsPopulated
* @Invoke       : From ADDTrendItemHandler class
* @Description  : Method to check required fields populating
* @Return       : N/A
* @Params       : N/A
**/
    static void isRequiredFieldsPopulated(String recordTypeId, SObject ttRecord,
            List<SObjectField> requiredFields, String errorMessage) {
        Boolean isEmpty = false;
        for (SObjectField field : requiredFields) {
            if (null == ttRecord.get(field)) {
                isEmpty = true;
                break;
            }
        }
        if ((String)ttRecord.get('RecordTypeId') == recordTypeId && isEmpty) {
            ttRecord.addError(errorMessage);
        }
    }

/**
* @Method       : beforeInsert
* @Invoke       : Events from TriggerHandler before insert
* @Description  : To handle all the logic in before insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeInsert() {
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        List<Trend_Item__c> newItems = (List<Trend_Item__c>)Trigger.New;
        for(Trend_Item__c item : newItems){
            actionPerformedByIds.add(item.CMPL123_WF_Action_Performed_By__c);
        }
        wfLogic(newItems, actionPerformedByIds, null);
        //TWD Upgrade issue end. 
    }
    
/**
* @Method       : afterInsert
* @Invoke       : Events from TriggerHandler after insert
* @Description  : To handle all the logic in after insert event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterInsert() {
        CMPL123.AuditHandler.handleAudit();        
    }
    
/**
* @Method       : beforeUpdate
* @Invoke       : Events from TriggerHandler before update
* @Description  : To handle all the logic in before update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeUpdate() {
        //TWD Upgrade issue start. 
        Set <Id> actionPerformedByIds = new Set <Id>();
        Map<Id, Trend_Item__c> oldRecordMap = (Map<Id, Trend_Item__c>)Trigger.oldMap;
        //TWD Upgrade issue end. 
        getRecordTypes();
        Map<Id, Trend_Item__c> newRecordMap = (Map<Id, Trend_Item__c>)Trigger.newMap;
        
        for(Trend_Item__c queriedTIRecord : [SELECT Id, CMPL123_WF_Action_Performed_By__c, CMPL123_WF_Action_Performed_On__c, CMPL123_WF_Action__c, RecordTypeId, RecordType.Name,
            Trend_Item_Type__c, (SELECT Id FROM Trend_Item_Issue_Codes__r),
            (SELECT Id FROM Trend_Item_Products__r), (SELECT Id FROM Trend_Item_Trend_Buckets__r)
            FROM Trend_Item__c WHERE Id IN: newRecordMap.keyset()]){
            
            Trend_Item__c currentTIRecord = newRecordMap.get(queriedTIRecord.Id);
            Trend_Item__c oldTIRecord = (Trend_Item__c)Trigger.oldMap.get(currentTIRecord.Id); 
            
            if(currentTIRecord.CMPL123_WF_Action__c == 'Activate' 
                && oldTIRecord.CMPL123_WF_Action__c != currentTIRecord.CMPL123_WF_Action__c){
                
                if(queriedTIRecord.Trend_Item_Products__r.size() == 0){
                    currentTIRecord.addError(System.Label.Trend_Item_Product_Error);
                } 
                else if(queriedTIRecord.Trend_Item_Issue_Codes__r.size() == 0
                    && currentTIRecord.RecordTypeId == thresholdRecordTypeId
                    && currentTIRecord.Trend_Item_Type__c == 'Process'){
                    currentTIRecord.addError(System.Label.Trend_Item_Issue_Code_Error);
                }
                else if(queriedTIRecord.Trend_Item_Trend_Buckets__r.size() == 0
                    && currentTIRecord.RecordTypeId == thresholdRecordTypeId
                    && (currentTIRecord.Trend_Item_Type__c == 'Assay' 
                        || currentTIRecord.Trend_Item_Type__c == 'Consumables' )){
                    currentTIRecord.addError(System.Label.Trend_Item_Trend_Buckets_Error);
                }

                isRequiredFieldsPopulated(submissionTT, currentTIRecord,
                        submissionTTRequiredFields, System.Label.Trend_Item_Submission_TT_Baseline_MDR_MDI_Error);
                isRequiredFieldsPopulated(ticketTT, currentTIRecord,
                        ticketTTComplaintRequiredFields, System.Label.Trend_Item_Ticket_TT_Baseline_Complaint_Error);
                isRequiredFieldsPopulated(ticketTT, currentTIRecord,
                        ticketTTServiceRequiredFields, System.Label.Trend_Item_Ticket_TT_Baseline_Service_Error);
            }
            //TWD Upgrade issue: add userIds to the list. 
            actionPerformedByIds.add(currentTIRecord.CMPL123_WF_Action_Performed_By__c);
        }
        //TWD Upgrade issue start. Call wfLogic
        wfLogic(newRecordMap.values(), actionPerformedByIds, oldRecordMap);
        //TWD Upgrade issue end. 
        CMPL123.AuditHandler.handleAudit(); 
    
    }
    
/**
* @Method       : afterUpdate
* @Invoke       : Events from TriggerHandler after update
* @Description  : To handle all the logic in after update event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void afterUpdate() {
        CMPL123.AuditHandler.handleAudit();
    }
    
/**
* @Method       : beforeDelete
* @Invoke       : Events from TriggerHandler before delete
* @Description  : To handle all the logic in before delete event
* @Return       : N/A
* @Params       : N/A
**/ 
    public override void beforeDelete() {
        CMPL123.AuditHandler.handleAudit();
    }  
    
/**
* @Method       : afterDelete
* @Invoke       : Events from TriggerHandler after delete
* @Description  : To handle all the logic in after delete event
* @Return       : N/A
* @Params       : N/A
**/  
    public override void afterDelete() {
    }  
    
    /*
    * @Method       : wfLogic.
    * @Description  : TWD Upgrade issue. Added logic from WF rules.
    * @Invoke       : From ADDTrendItemHandler class.
    * @Return       : N/A.
    * @Params       : List<Trend_Item__c> items, Set<Id> userIds, Map <Id, Trend_Item__c> oldItemById.
    */
    
    public static void wfLogic(List<Trend_Item__c> items, Set<Id> userIds, Map <Id, Trend_Item__c> oldItemById) {
        Map<Id, User> userById = new Map <Id, User>(
                        [SELECT LastName, FirstName
                        FROM User
                        WHERE Id in: userIds]);
        for (Trend_Item__c item: items) {
            if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Workflow_Updates__c){
                
                //WF: Workflow - Activate
                if (item.CMPL123_WF_Action__c == 'Activate' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Activated_By__c = userById.get(item.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(item.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        item.Activated_On__c = item.CMPL123_WF_Action_Performed_On__c;
                        if (userById.get(item.CMPL123_WF_Action_Performed_By__c)?.FirstName == null) {
                            item.Activated_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
                        }
                }
                //WF: Workflow - Inactivate 
                if (item.CMPL123_WF_Action__c == 'Inactivate' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Inactivated_By__c = userById.get(item.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(item.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        item.Inactivated_On__c = item.CMPL123_WF_Action_Performed_On__c;
                }
                //WF: Workflow - Reactivate 
                if (item.CMPL123_WF_Action__c == 'Reactivate' && (oldItemById == null || (oldItemById != null 
                    && oldItemById.get(item.Id).CMPL123_WF_Action__c != item.CMPL123_WF_Action__c)) ) {
                        item.Reactivated_By__c = userById.get(item.CMPL123_WF_Action_Performed_By__c)?.FirstName + ' ' + 
                                              userById.get(item.CMPL123_WF_Action_Performed_By__c)?.LastName;
                        item.Reactivated_On__c = item.CMPL123_WF_Action_Performed_On__c;
                }
            }
        }
    }
}
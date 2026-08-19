/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : CMPL123CME_EMDR_AuditTrigger
* @Why   : To Handles all the customization involved on     CMPL123CME__EMDR__c object.
* @When  : 07-FEB-2019  
* @Where : From     CMPL123CME__EMDR__c object Events
 ----------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    07-FEB-2019            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    09-JUNE-2020           #123/CHARM-2729      Added parent ticket LastModifiedDate updating
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    27-OCT-2020            HC #100/CHARM-3518   Added validation upon Pending Follow Up Creation.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                    03-NOW-2020            HC #100/CHARM-3518   Adjusted validation upon Pending Follow Up Creation 
*                                                                        and Pending Closure statuses.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger CMPL123CME_EMDR_AuditTrigger on CMPL123CME__EMDR__c (before insert, before update,before delete,after insert,after update)
{
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) 
    {
        TicketUtil.addTrace('CMPL123CME_EMDR_AuditTrigger');
        if(Trigger.isInsert && Trigger.isBefore)
        {
          
           EMDRTriggerHandler.beforeInsertHandler(); 
           CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler generateMFRNo = new 
                CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler ();
            generateMFRNo.emdrGenerateMFRReportNo();
            System.debug('cpu  insertion - is before insert emdr' + Limits.getCpuTime());
        }
        
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter)
        {
           // EMDRProcessBuilderFunctionality.medevalfieldUpdate();
            EMDRTriggerHandler.afterInsertHandler();
            CMPL123.AuditHandler.handleAudit();
            System.debug('cpu after handle audit: - after insert emdr' + Limits.getCpuTime());

            
           CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler generateMFRNo = new 
            CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler ();
            generateMFRNo.emdrGenerateMFRReportNo();
            
            if(UpdateParentUtility.flag){
                UpdateParentUtility.flag = false;
                Set<Id> productticketRecordIdSet = new Set<Id>();
                for(CMPL123CME__EMDR__c emdrCode : Trigger.new){
                    if(emdrCode.Product__c != null)
                        productticketRecordIdSet.add(emdrCode.Product__c);              
                }
                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
            // Defect #123/CHARM-2729: update parent ticket LastModifiedDate
            EMDRTriggerHandler.updateTicketLastModifiedDate();
        }
        
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore) 
        {

            // HC #100/CHARM-3518: validation upon Pending Follow Up Creation.
            if (!EMDRTriggerHandler.isEditAccessOnPendingChecked) 
            {
                Set<String> lockedStatuses = new Set<String>{'Pending Follow Up Creation', 'Pending Closure'};
                CustomRecordLockingUtil.validateRecordEdit(
                    Trigger.newMap,
                    Trigger.oldMap,
                    'CMPL123CME__CMPL123_WF_Status__c',
                    lockedStatuses,
                    EMDRTriggerHandler.getEditableOnPendingFields(lockedStatuses)
                );
                EMDRTriggerHandler.isEditAccessOnPendingChecked = true;
            }
            List<CMPL123CME__EMDR__c> lstEMDRsNew = (List<CMPL123CME__EMDR__c>)Trigger.New;
            Map<Id, CMPL123CME__EMDR__c> emdrOldMap = (Map<Id, CMPL123CME__EMDR__c>)Trigger.oldMap;
            EMDRTriggerHandler.checkEditability(lstEMDRsNew, emdrOldMap);
            //EMDRTriggerHandler.addCurrentTimeToDateFields( lstEMDRsNew, emdrOldMap );
            Boolean isDueDateChanged = false;
            
            //Validate record lock on Submitted to TIBCO
            if(EmdrRecordLockUtility.executeOnce){
                EmdrRecordLockUtility.executeOnce = false;
                EmdrRecordLockUtility.validateRecordUpdateOnSubmittedToTibco((List<CMPL123CME__EMDR__c>)Trigger.new, (Map<Id,CMPL123CME__EMDR__c>)Trigger.oldMap);
            }
            
            for(CMPL123CME__EMDR__c emdr : Trigger.New)
            {
                if(emdr.CMPL123CME__MDR_Due_Date__c   != Trigger.oldMap.get(emdr.Id).CMPL123CME__MDR_Due_Date__c)
                {
                    isDueDateChanged = true;
                }
             }
             
            //Defect no 80
            if(!isDueDateChanged){
                // #123/CHARM-2729: skip custom logic if only LastModifiedDate is updated
                if (!EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild) {
                    EMDRTriggerHandler.beforeUpdateHandler();
                }
                
                CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler generateMFRNo = new 
                    CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler ();
                generateMFRNo.emdrGenerateMFRReportNo();

            }
            EMDRTriggerHandler.isBeforeUpdateExecuted = true;
            CMPL123.AuditHandler.handleAudit();
            System.debug('cpu after handle audit: - before update  emdr' + Limits.getCpuTime());

        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter)
        {
            if(UpdateParentUtility.flag){
                UpdateParentUtility.flag = false;
                Set<Id> productticketRecordIdSet = new Set<Id>();
                for(CMPL123CME__EMDR__c emdrCode : Trigger.new){
                    if(emdrCode.Product__c != null)
                        productticketRecordIdSet.add(emdrCode.Product__c);              
                }
                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
            Boolean isDueDateChanged = false;
            for(CMPL123CME__EMDR__c emdr : Trigger.New){
                if(emdr.CMPL123CME__MDR_Due_Date__c   != Trigger.oldMap.get(emdr.Id).CMPL123CME__MDR_Due_Date__c){
                    isDueDateChanged = true;
                }
                
            }
            if(!isDueDateChanged){
                CMPL123.AuditHandler.handleAudit();
                System.debug('cpu after handle audit: - after update emdr' + Limits.getCpuTime());

                // #123/CHARM-2729: skip custom logic if only LastModifiedDate is updated
                if (!EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild) {
                    EMDRTriggerHandler.afterUpdateHandler();
                }
                // EMDRProcessBuilderFunctionality.medevalfieldUpdate();
                
                CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler generateMFRNo = new 
                    CMPL123CME.EMDR_GenerateMFRReportNoTriggerHandler ();
                generateMFRNo.emdrGenerateMFRReportNo(); 
            }
            // Defect #123/CHARM-2729: update parent ticket LastModifiedDate
            EMDRTriggerHandler.updateTicketLastModifiedDate();
        }
        
        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore)
        {
            CMPL123.AuditHandler.handleAudit();
        }
        
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter)
        {
             // Place your code. 
        }
    }
    
}
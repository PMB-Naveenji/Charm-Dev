/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Regulatory_Task_AuditTrigger
* @Why   : To Handles all the customization involved on Regulatory_Task__c object.
* @When  : 07-FEB-2019  
* @Where : From Regulatory_Task__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*   rsitc                  09-JUNE-2020             #123/CHARM-2729      Added updateMDILastModifiedDate method call.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Regulatory_Task_AuditTrigger on Regulatory_Task__c (before insert, before update,before delete,after insert,after update,after delete){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDRegulatoryTaskTriggerHandler().run();
        
        /* After Insert */
        if(Trigger.isInsert && Trigger.isAfter){
     ADDRegulatoryTaskTriggerHandler.updateMDILastModifiedDate();
            if(UpdateParentUtility.flag){
                UpdateParentUtility.flag = false;
                Set<Id> meddevRecordIdSet = new Set<Id>();
                for(Regulatory_Task__c regtrytaskCode : Trigger.new){
                    if(regtrytaskCode.MDI__c!=null)
                    meddevRecordIdSet.add(regtrytaskCode.MDI__c);
                    //Start code changes for Sprint 4
                    if(regtrytaskCode.EU_MIR__c!=null)
                    meddevRecordIdSet.add(regtrytaskCode.EU_MIR__c); 
                }
                //End for Sprint 4 code changes
                if(!meddevRecordIdSet.isEmpty())
                UpdateParentUtility.updateparent_trend(meddevRecordIdSet);
            }
        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
     ADDRegulatoryTaskTriggerHandler.updateMDILastModifiedDate();
            try{
                if(UpdateParentUtility.flag){
                    UpdateParentUtility.flag = false;
                    Set<Id> meddevRecordIdSet = new Set<Id>();
                    for(Regulatory_Task__c regtrytaskCode : Trigger.new){
                        if(regtrytaskCode.MDI__c!=null)
                            meddevRecordIdSet.add(regtrytaskCode.MDI__c); 
                        //Start code changes for Sprint 4
                        if(regtrytaskCode.EU_MIR__c!=null)
                            meddevRecordIdSet.add(regtrytaskCode.EU_MIR__c); 
                    }
                    //End for Sprint 4 code changes
                    if(!meddevRecordIdSet.isEmpty())
                        UpdateParentUtility.updateparent_trend(meddevRecordIdSet);
                }
            }catch(Exception ex){
                System.debug('$$ EXCEPTION = '+ex.getMessage());
                System.debug('$$ EXCEPTION = '+ex.getLineNumber());
                System.debug('$$ EXCEPTION = '+ex.getStackTraceString());
                throw ex;
            }            
        }                
    }
}
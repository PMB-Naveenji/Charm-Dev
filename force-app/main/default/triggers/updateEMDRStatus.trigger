/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : updateEMDRStatus
* @Why   : To Handles all the customization involved on CMPL123CME__Submission_History__c object.
* @When  : 07-FEB-2019
* @Where : From CMPL123CME__Submission_History__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID               Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin            07-FEB-2019          Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Soumith          10-JAN-2025              CHaRM R6.0/IPDR 552             Updated After Insert trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger updateEMDRStatus on CMPL123CME__Submission_History__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        CMPL123.X123TriggerHandler X123handler = new CMPL123.X123TriggerHandler();
        
        /* Before Insert */
        if(Trigger.isInsert && Trigger.isBefore){
            // Place your custom code here 
            X123handler.handleBeforeInsert();
        } 
        if(Trigger.isAfter && Trigger.isInsert){
            List<CMPL123CME__EMDR__c> updateableEMDR = new List<CMPL123CME__EMDR__c>();
            Set<Id> emdrIds = new Set<Id>();
            Set<Id> parentEmdrIds = new Set<Id>();
            Map<Id, String> eMDRIdCoreIdMap = new Map<Id, String>();
            
            for(CMPL123CME__Submission_History__c submissionHistory : Trigger.New){
                if(null != submissionHistory.CMPL123CME__Related_EMDR__c) {
                    parentEmdrIds.add(submissionHistory.CMPL123CME__Related_EMDR__c);
                }
            }
            Map<Id, CMPL123CME__EMDR__c> parentEMDRMap = new Map<Id, CMPL123CME__EMDR__c>([
                SELECT Id, CMPL123CME__CMPL123_WF_Status__c
                FROM CMPL123CME__EMDR__c
                WHERE Id IN : parentEmdrIds
            ]);
            
            for(CMPL123CME__Submission_History__c submissionHistory : Trigger.New){
                Id parentEMDRId = submissionHistory.CMPL123CME__Related_EMDR__c;
                if(submissionHistory.CMPL123CME__Stage__c == 'Draft' && (submissionHistory.CMPL123CME__Status__c == 'Internal Error'
                                                                         || submissionHistory.CMPL123CME__Status__c == 'Failed')) {
                                                                             CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c();
                                                                             emdr.Id = parentEMDRId;
                                                                             // Avoid case when reopening has already been performed by Sys Admin manually
                                                                             if (parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened') {
                                                                                 emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.Parent_Record_Type__c  == 'Initial'
                                                                                     ? 'SUBMITTEDTOFDAFAIL' : 'SUBMITTEDTOFDAFAILSUPP' ;
                                                                             }
                                                                             emdr.CMPL123CME__MDR_Submission__c = 'Not Submitted' ;
                                                                             emdr.CMPL123CME__CMPL123_WF_Action__c = '';
                                                                             updateableEMDR.add(emdr);
                                                                         }
                if(submissionHistory.CMPL123CME__Stage__c == 'Submitted') {
                    CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c();
                    emdr.Id = parentEMDRId;
                    emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.Parent_Record_Type__c  == 'Initial'
                        ? 'SUBMITTEDTOFDA' : 'SUBMITTEDTOFDASUPP';
                    emdr.CMPL123CME__MDR_Submission__c = 'Submitted';
                    emdr.CMPL123CME__CMPL123_WF_Action__c = '';
                    updateableEMDR.add(emdr);
                }
                else if(submissionHistory.CMPL123CME__Stage__c == 'ACK1') {
                    CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c();
                    emdr.Id = parentEMDRId;
                    if(submissionHistory.Parent_Record_Type__c  == 'Initial'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'ACK1PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'ACK1FAIL' : null;
                    }
                    
                    if(submissionHistory.Parent_Record_Type__c  == 'Supplemental'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'SUPPACK1PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'SUPPACK1FAIL' : null;
                    }
                    //CHaRM R6: IPDR 552- start- autopopulating the CMPL123CME__Submitted_Date_Time__c field in EMDR with CMPL123CME__FDA_Submission_Date__c from Submission History object when successful ACK 1 is received.
                    if(submissionHistory.CMPL123CME__Status__c == 'Passed'){
                    emdr.CMPL123CME__Submitted_Date_Time__c = submissionHistory.CMPL123CME__FDA_Submission_Date__c;
                    }
                    //CHaRM R6: IPDR 552- End
                    emdr.CMPL123CME__MDR_Submission__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'Submitted' : 'Not Submitted' ;
                    //CHaRM R6: Commented the below code as we are autopopulating the CMPL123CME__Submitted_Date_Time__c field with CMPL123CME__FDA_Submission_Date__c from Submission History object.
                   // emdr.CMPL123CME__Submitted_Date_Time__c = System.now();
                                        
                    updateableEMDR.add(emdr);
                }
                else if(submissionHistory.CMPL123CME__Stage__c == 'ACK2') {
                    CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c();
                    emdr.Id = parentEMDRId;
                    if(submissionHistory.Parent_Record_Type__c  == 'Initial'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'ACK2PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'ACK2FAIL' : null;
                    }
                    if(submissionHistory.Parent_Record_Type__c  == 'Supplemental'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'SUPPACK2PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'SUPPACK2FAIL' : null;
                    }
                    emdr.CMPL123CME__MDR_Submission__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'Submitted' : 'Not Submitted' ;
                    updateableEMDR.add(emdr);                    
                }
                else if(submissionHistory.CMPL123CME__Stage__c == 'ACK3') {
                    CMPL123CME__EMDR__c emdr = new CMPL123CME__EMDR__c();
                    emdr.Id = parentEMDRId;
                    if(submissionHistory.Parent_Record_Type__c  == 'Initial'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'ACK3PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'ACK3FAIL' : null;
                    }
                    if(submissionHistory.Parent_Record_Type__c  == 'Supplemental'){
                        emdr.CMPL123CME__CMPL123Task_Key_Value__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'SUPPACK3PASS'
                            : parentEMDRMap.get(parentEMDRId).CMPL123CME__CMPL123_WF_Status__c != 'Opened' ? 'SUPPACK3FAIL' : null;
                    }
                    emdr.CMPL123CME__MDR_Submission__c = submissionHistory.CMPL123CME__Status__c == 'Passed' ? 'Submitted' : 'Not Submitted' ;                    
                    updateableEMDR.add(emdr);
                }
                if(submissionHistory.CMPL123CME__Stage__c != 'Submitted' && submissionHistory.CMPL123CME__Stage__c != 'Draft'){
                    emdrIds.add(parentEMDRId);
                    if(submissionHistory.CMPL123CME__Core_Id__c != null)
                        eMDRIdCoreIdMap.put(parentEMDRId, submissionHistory.CMPL123CME__Core_Id__c);
                }
            }
            if(updateableEMDR != null && updateableEMDR.size() > 0){
                update updateableEMDR;
            }
            if(emdrIds.size() > 0){
                try{
                    //below update on submission history submitted records is to recalculate 
                    //timebased workflow triggers on missing ACK's
                    List<CMPL123CME__Submission_History__c> updateableSubmissions = new List<CMPL123CME__Submission_History__c>();
                    for(CMPL123CME__Submission_History__c s : [SELECT Id,CMPL123CME__Core_Id__c,CMPL123CME__Related_EMDR__c FROM CMPL123CME__Submission_History__c WHERE 
                                                               CMPL123CME__Related_EMDR__c IN: emdrIds AND CMPL123CME__Stage__c = 'Submitted' 
                                                               AND CMPL123CME__Status__c = 'Passed']){                                                                   
                                                                   if(eMDRIdCoreIdMap != null && eMDRIdCoreIdMap.keyset().contains(s.CMPL123CME__Related_EMDR__c)){
                                                                       s.CMPL123CME__Core_Id__c = eMDRIdCoreIdMap.get(s.CMPL123CME__Related_EMDR__c);
                                                                   }  
                                                                   updateableSubmissions.add(s);
                                                               }
                    update updateableSubmissions;
                }catch(DMLException de){
                    System.debug('DML exception while updating submission history records'+de.getMessage());    
                }
            }
            X123handler.handleAfterInsert();
        }
        else if(Trigger.isUpdate && Trigger.isBefore){
            // Place your custom code here 
            X123handler.handleBeforeUpdate();
        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            // Place your custom code here 
            X123handler.handleAfterUpdate();
        }
        
        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore){
            // Place your custom code here 
            X123handler.handleBeforeDelete();
        }
        
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter){
            // Place your custom code here 
            X123handler.handleAfterDelete();
        }
        
        /* After UnDelete */
        else if(Trigger.isUnDelete && Trigger.isAfter){
            // Place your custom code here 
            X123handler.handleAfterUnDelete();
        }    
    }
    
}
/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who : Copyright (c) 2019 Capgemini.
* @What : CMPL123CME_EU_MIR_AuditTrigger
* @Why : To Handles all the customization involved on CMPL123CME__EU_MIR__c object.
* @When : 12-SEP-2019
* @Where : From CMPL123CME__EU_MIR__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer Date Modification ID Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin         12-SEP-2019     Work ID / Case ID   Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* L. Resnik     02-AUG-2021     CHaRM Release 2     Merged some After Update and After Insert logic
* --------------------------------------------------------------------------------------------------------------------------------
* Juneid        07-SEP-2021   CHaRM MIR Release     Added new Method updateFiledsOnRealtedProductIdChange to Fix defect #113
* --------------------------------------------------------------------------------------------------------------------------------------
* Davis         08-SEP-2021   CHaRM MIR Release (Release 2) Defect #104 Fix: Checks edit access
* --------------------------------------------------------------------------------------------------------------------------------------
* Rohit         11-NOV-2026   CHaRM R8 : Updated the Before Insert context to populate Follow-up EU MIR fields from parent MIR via handler.
**/
trigger CMPL123CME_EU_MIR_123Trigger on CMPL123CME__EU_MIR__c (before insert, before update,after insert,after update){
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('CMPL123CME_EU_MIR_AuditTrigger');

        CMPL123.X123TriggerHandler X123handler = new CMPL123.X123TriggerHandler();
        /* Before Insert */
        if(Trigger.isInsert && Trigger.isBefore){
            //@Juneid , Code Optimization
            Set<Id> countryID = new Set<Id>();
            Set<Id> ticketss = new Set<Id>();
            Set<Id> medicalEvalID = new Set<Id>();
            Set<Id> products = new Set<Id>();
            Set<Id> ticketIdSet = new Set<Id>();
            Set<Id> registeredSite = new Set<Id>();
           
           
            for(CMPL123CME__EU_MIR__c MIRs : Trigger.New){
                  if(MIRs.CMPL123CME__Type_Of_Report__c == AspenConstants.STR_Initial_Report){
                    
                    
                    ticketIdSet.add(MIRs.CMPL123CME__Complaint__c);
                    if(MIRs.MedicalEvaluation__c != null){
                        medicalEvalID.add(MIRs.MedicalEvaluation__c);
                    }
                    if(MIRs.Product__c != null){
                        products.add(MIRs.Product__c);
                    }
                    if(MIRs.CMPL123CME__Complaint__c != null){
                        ticketss.add(MIRs.CMPL123CME__Complaint__c);
                    }
                    if(MIRs.Registered_Site__c != null){
                        registeredSite.add(MIRs.Registered_Site__c);
                    }
                    countryID.add(MIRs.Country__c);
                }
            }
            EUMIRTriggerHandler.intialEuMirFieldUpdateOnInsert(ticketIdSet,medicalEvalID,products,ticketss,registeredSite,countryID,Trigger.New);
            EUMIRTriggerHandler.setDueDateOnMIR(Trigger.new,Trigger.oldMap);
            EUMIRTriggerHandler.updateLastModifiedDateAndTime(Trigger.new);
            //CHaRM R8: Populate Follow-up EU MIR fields from parent MIR via handler.
            EUMIRTriggerHandler.updateFolloUpEUMIRFields(Trigger.new);
            // Place your custom code here
            X123handler.handleBeforeInsert();
        }
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            //TODO Should we need to migrate into the Helper,MID Having Same Logic
            if(UpdateParentUtility.flag){
                UpdateParentUtility.flag = false;
                Set<Id> productticketRecordIdSet = new Set<Id>();
                for(CMPL123CME__EU_MIR__c mirdevCode : Trigger.new){
                    if(mirdevCode.Product__c != null){
                        productticketRecordIdSet.add(mirdevCode.Product__c);
                    }
                }
                UpdateParentUtility.updateparent_trend(productticketRecordIdSet);
            }
            // Place your custom code here
            X123handler.handleAfterInsert();
        }
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore){
            system.debug('inside before update---->');
            //Davis Defect #104 fix: checks edit access.
            if (!EUMIRTriggerHandler.isEditAccessOnPendingChecked) {
                EUMIRTriggerHandler.checkEditableOnPendingStatus('CMPL123_WF_Status__c');
                EUMIRTriggerHandler.isEditAccessOnPendingChecked = true;
            }
         
            //@Juneid 24 June 2021,Calling method for Update fields of WF Actions
            EUMIRTriggerHandler.updateFiledsOnWFActions(Trigger.NewMap,Trigger.oldMap);
            EUMIRTriggerHandler.beforeUpdateHandler();
            EUMIRTriggerHandler.checkRegulatoryTaskBeforeVoid(Trigger.NewMap,Trigger.oldMap);
            EUMIRTriggerHandler.updateLastModifiedDateAndTime(Trigger.new);
            // Place your custom code here
            X123handler.handleBeforeUpdate();
        }
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            EUMIRTriggerHandler.afterUpdateHandler(Trigger.New,Trigger.oldMap);
            EUMIRTriggerHandler.medEvalFieldPopulationMIR(Trigger.newMap, Trigger.oldMap);
            EUMIRTriggerHandler.updateFiledsOnRealtedProductIdChange(Trigger.NewMap,Trigger.oldMap);
            EUMIRTriggerHandler.updateParentTrend(
                (List<CMPL123CME__EU_MIR__c>)Trigger.new, 
                (Map<Id, CMPL123CME__EU_MIR__c>)Trigger.oldMap);
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